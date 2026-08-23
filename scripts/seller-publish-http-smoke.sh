#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5097}"
WEB_PORT="${BPT_SELLER_PUBLIC_WEB_PORT:-3097}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
CLIENT_ID="BomPraTi_SellerWeb"
REDIRECT_URI="${WEB_BASE}/vender/callback"
TMP="${TMPDIR:-/tmp}/bpt2-seller-publish"
API_LOG="${TMP}/api.log"
WEB_LOG="${TMP}/web.log"
RESPONSE="${TMP}/response.json"
HEADERS="${TMP}/headers.txt"
COOKIES="${TMP}/cookies.txt"
LOGIN_HTML="${TMP}/login.html"
TOKEN_JSON="${TMP}/token.json"
DISCOVERY="${TMP}/discovery.json"
SWAGGER="${TMP}/swagger.json"
HOME_HTML="${TMP}/home.html"
DETAIL_HTML="${TMP}/detail.html"
PUBLIC_PHOTO="${TMP}/public-photo.bin"
PNG="${TMP}/photo.png"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false
export OpenIddict__Applications__BomPraTi_SellerWeb__RootUrl="$WEB_BASE"
export BPT_MEDIA_ROOT="${BPT_MEDIA_ROOT:-${TMP}/media}"
mkdir -p "$BPT_MEDIA_ROOT"

API_PID=""
WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$API_BASE$path"
}

location() {
  python3 - "$1" <<'PY'
import sys
value = None
with open(sys.argv[1], encoding="iso-8859-1") as handle:
    for line in handle:
        if line.lower().startswith("location:"):
            value = line.split(":", 1)[1].strip()
if not value:
    raise SystemExit("Missing Location header")
print(value)
PY
}

resolve_url() {
  python3 - "$API_BASE" "$1" <<'PY'
import sys
from urllib.parse import urljoin
print(urljoin(sys.argv[1] + "/", sys.argv[2]))
PY
}

get_fixture_token() {
  local username="$1"
  local password="$2"
  local token_file="${TMP}/fixture-token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Fixture token for $username failed: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Fixture token response missing access_token")
print(token)
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/.well-known/openid-configuration" -o "$DISCOVERY" \
    && curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then
    cat "$API_LOG" >&2
    exit 1
  fi
  sleep 1
done
[[ -s "$DISCOVERY" && -s "$SWAGGER" ]] || { cat "$API_LOG" >&2; exit 1; }

python3 - "$SWAGGER" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    paths = json.load(handle).get("paths", {})
required = [
    ("/api/app/media-upload/upload", "post"),
    ("/api/app/listing-photo/attach/{listingId}", "post"),
    ("/api/app/listing-photo/reorder/{listingId}", "post"),
    ("/api/app/listing-photo", "delete"),
    ("/api/app/listing-command/publish/{listingId}", "post"),
    ("/api/app/listing-command/pause/{listingId}", "post"),
    ("/api/app/listing-command/archive/{listingId}", "post"),
    ("/api/app/seller-listing-query/mine-by-id/{listingId}", "get"),
    ("/api/app/public-listing/{id}", "get"),
]
missing = [f"{verb.upper()} {path}" for path, verb in required if verb not in paths.get(path, {})]
if missing:
    raise SystemExit(f"Seller publish frontend contract does not match Swagger: {missing}; available={sorted(paths)}")
remove = paths["/api/app/listing-photo"]["delete"]
query = {(item.get("name", "").lower(), item.get("in")) for item in remove.get("parameters", [])}
if ("listingid", "query") not in query or ("photoid", "query") not in query:
    raise SystemExit(f"Photo remove must expose listingId/photoId query params: {remove.get('parameters', [])}")
media = paths["/api/app/media-upload/upload"]["post"].get("requestBody", {}).get("content", {})
if not any(key.lower().startswith("multipart/form-data") for key in media):
    raise SystemExit(f"Media upload must be multipart/form-data: {sorted(media)}")
PY
echo "SELLER_PUBLISH_ROUTES: PASS"

python3 - "$DISCOVERY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for key in ("authorization_endpoint", "token_endpoint"):
    if not data.get(key):
        raise SystemExit(f"OIDC discovery missing {key}")
if "S256" not in data.get("code_challenge_methods_supported", []):
    raise SystemExit("OIDC discovery does not advertise S256 PKCE")
PY

read -r CODE_VERIFIER CODE_CHALLENGE STATE < <(python3 <<'PY'
import base64, hashlib, secrets
verifier = secrets.token_urlsafe(72)[:96]
challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
print(verifier, challenge, secrets.token_urlsafe(24))
PY
)

AUTH_URL="$(python3 - "$API_BASE" "$CLIENT_ID" "$REDIRECT_URI" "$CODE_CHALLENGE" "$STATE" <<'PY'
import sys
from urllib.parse import urlencode
base, client, redirect, challenge, state = sys.argv[1:]
print(base + "/connect/authorize?" + urlencode({
    "client_id": client,
    "redirect_uri": redirect,
    "response_type": "code",
    "scope": "openid profile email roles BomPraTi",
    "code_challenge": challenge,
    "code_challenge_method": "S256",
    "state": state,
}))
PY
)"

status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTH_URL")"
[[ "$status" == "302" ]] || { cat "$RESPONSE" >&2; echo "Seller authorize expected 302, got $status" >&2; exit 1; }
LOGIN_URL="$(resolve_url "$(location "$HEADERS")")"
LOGIN_EFFECTIVE="$(curl --silent --show-error --location --max-redirs 5 --cookie "$COOKIES" --cookie-jar "$COOKIES" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$LOGIN_URL")"
REQUEST_TOKEN="$(python3 - "$LOGIN_HTML" <<'PY'
from html.parser import HTMLParser
import sys
class Parser(HTMLParser):
    value = None
    def handle_starttag(self, tag, attrs):
        if tag.lower() != "input":
            return
        values = dict(attrs)
        if values.get("name") == "__RequestVerificationToken":
            self.value = values.get("value")
parser = Parser()
with open(sys.argv[1], encoding="utf-8") as handle:
    parser.feed(handle.read())
if not parser.value:
    raise SystemExit("Login antiforgery token not found")
print(parser.value)
PY
)"

status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' \
  --request POST "$LOGIN_EFFECTIVE" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "__RequestVerificationToken=$REQUEST_TOKEN" \
  --data-urlencode 'LoginInput.UserNameOrEmailAddress=admin' \
  --data-urlencode 'LoginInput.Password=1q2w3E*' \
  --data-urlencode 'LoginInput.RememberMe=false' \
  --data-urlencode 'Action=Login')"
[[ "$status" == "302" ]] || { cat "$RESPONSE" >&2; echo "Account login expected 302, got $status" >&2; exit 1; }
AUTHORIZED_URL="$(resolve_url "$(location "$HEADERS")")"
status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTHORIZED_URL")"
[[ "$status" == "302" ]] || { cat "$RESPONSE" >&2; echo "Authenticated authorize expected 302, got $status" >&2; exit 1; }
CALLBACK_URL="$(location "$HEADERS")"

read -r AUTH_CODE RETURNED_STATE < <(python3 - "$CALLBACK_URL" "$REDIRECT_URI" <<'PY'
import sys
from urllib.parse import parse_qs, urlparse
url, expected_url = sys.argv[1:]
parsed = urlparse(url)
expected = urlparse(expected_url)
if (parsed.scheme, parsed.netloc, parsed.path) != (expected.scheme, expected.netloc, expected.path):
    raise SystemExit(f"Unexpected Seller callback URL: {url}")
query = parse_qs(parsed.query)
print(query["code"][0], query["state"][0])
PY
)
[[ "$RETURNED_STATE" == "$STATE" ]] || { echo "OIDC state mismatch" >&2; exit 1; }

status="$(curl --silent --show-error --output "$TOKEN_JSON" --write-out '%{http_code}' \
  --request POST "$API_BASE/connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=authorization_code' \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "code=$AUTH_CODE" \
  --data-urlencode "redirect_uri=$REDIRECT_URI" \
  --data-urlencode "code_verifier=$CODE_VERIFIER")"
[[ "$status" == "200" ]] || { cat "$TOKEN_JSON" >&2; echo "Seller PKCE exchange expected 200, got $status" >&2; exit 1; }
TOKEN="$(python3 - "$TOKEN_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if not data.get("access_token"):
    raise SystemExit(f"Token response missing access_token: {data}")
print(data["access_token"])
PY
)"
echo "SELLER_PUBLISH_PKCE_LOGIN: PASS"

PROFILE='{"displayName":"BPT Seller Publish","whatsAppNumber":"+55 (11) 97777-6655"}'
status="$(request_json POST '/api/app/seller-profile/upsert' "$TOKEN" "$PROFILE")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Profile upsert expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }

echo "SELLER_PUBLISH_PROFILE: PASS"

LISTING_TITLE="Seller Publish Flow"
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$LISTING_TITLE" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": sys.argv[2],
    "price": 162500,
    "description": "Fluxo completo Seller com fotos e publicação.",
    "manufactureYear": 2024,
    "mileageKm": 9300,
    "color": "Prata",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Draft create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
read -r LISTING_ID STAMP < <(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft" or not data.get("concurrencyStamp"):
    raise SystemExit(f"Listing did not start Draft with stamp: {data}")
print(data["id"], data["concurrencyStamp"])
PY
)

status="$(request_json GET '/api/app/seller-listing-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || { echo "My Listings expected 200, got $status" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if not any(str(item.get("id", "")).lower() == sys.argv[2].lower() for item in data):
    raise SystemExit(f"Draft missing from My Listings: {data}")
PY

echo "SELLER_PUBLISH_DRAFT_MY_LISTINGS: PASS"

UPDATE_BODY="$(python3 - "$STAMP" <<'PY'
import json, sys
print(json.dumps({
    "title": "Seller Publish Flow Updated",
    "price": 163900,
    "concurrencyStamp": sys.argv[1],
    "description": "Fluxo completo Seller atualizado antes das fotos.",
    "manufactureYear": 2024,
    "mileageKm": 9100,
    "color": "Prata",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json PUT "/api/app/listing-command?listingId=$LISTING_ID" "$TOKEN" "$UPDATE_BODY")"
[[ "$status" == "200" ]] || { echo "Draft edit expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_TITLE="Seller Publish Flow Updated"
echo "SELLER_PUBLISH_EDIT: PASS"

upload() {
  curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
    --request POST "$API_BASE/api/app/media-upload/upload" \
    -H "Authorization: Bearer $TOKEN" \
    -F "content=@${PNG};type=image/png"
}

status="$(upload)"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Photo 1 upload failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_1="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for forbidden in ("storageKey", "provider", "storageProvider"):
    if forbidden in data:
        raise SystemExit(f"Storage internals leaked: {data}")
print(data["id"])
PY
)"
status="$(upload)"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Photo 2 upload failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_2="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["id"])
PY
)"
[[ "$MEDIA_1" != "$MEDIA_2" ]] || { echo "Uploads returned same MediaAssetId" >&2; exit 1; }
echo "SELLER_PUBLISH_UPLOAD: PASS"

attach_body() {
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"mediaAssetId": sys.argv[1]}))
PY
}
status="$(request_json POST "/api/app/listing-photo/attach/$LISTING_ID" "$TOKEN" "$(attach_body "$MEDIA_1")")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Photo 1 attach failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_1="$(python3 - "$RESPONSE" "$MEDIA_1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
match = next(item for item in data if str(item.get("mediaAssetId", "")).lower() == sys.argv[2].lower())
print(match["id"])
PY
)"
status="$(request_json POST "/api/app/listing-photo/attach/$LISTING_ID" "$TOKEN" "$(attach_body "$MEDIA_2")")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Photo 2 attach failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_2="$(python3 - "$RESPONSE" "$MEDIA_2" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
match = next(item for item in data if str(item.get("mediaAssetId", "")).lower() == sys.argv[2].lower())
print(match["id"])
PY
)"

REORDER_BODY="$(python3 - "$PHOTO_2" "$PHOTO_1" <<'PY'
import json, sys
print(json.dumps({"photoIds": [sys.argv[1], sys.argv[2]]}))
PY
)"
status="$(request_json POST "/api/app/listing-photo/reorder/$LISTING_ID" "$TOKEN" "$REORDER_BODY")"
[[ "$status" == "200" ]] || { echo "Photo reorder failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$PHOTO_2" "$PHOTO_1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
ids = [str(item.get("id", "")).lower() for item in data]
expected = [sys.argv[2].lower(), sys.argv[3].lower()]
if ids != expected or [item.get("sortOrder") for item in data] != [0, 1]:
    raise SystemExit(f"Unexpected photo order: {data}")
PY

echo "SELLER_PUBLISH_REORDER: PASS"

status="$(request_json DELETE "/api/app/listing-photo?listingId=$LISTING_ID&photoId=$PHOTO_1" "$TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Photo remove failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json GET "/api/app/seller-listing-query/mine-by-id/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Owned detail reread failed: $status" >&2; exit 1; }
python3 - "$RESPONSE" "$PHOTO_2" "$MEDIA_2" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
photos = data.get("photos", [])
if len(photos) != 1 or str(photos[0].get("id", "")).lower() != sys.argv[2].lower():
    raise SystemExit(f"Unexpected gallery after remove: {data}")
if str(photos[0].get("mediaAssetId", "")).lower() != sys.argv[3].lower() or photos[0].get("sortOrder") != 0:
    raise SystemExit(f"Remaining photo was not normalized: {data}")
PY
echo "SELLER_PUBLISH_REMOVE: PASS"

OTHER_USER="seller-publish-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:10])
PY
)"
OTHER_PASSWORD='Bpt2-PublishSeller-9!x'
OTHER_EMAIL="${OTHER_USER}@example.invalid"
OTHER_BODY="$(python3 - "$OTHER_USER" "$OTHER_EMAIL" "$OTHER_PASSWORD" <<'PY'
import json, sys
username, email, password = sys.argv[1:]
print(json.dumps({
    "userName": username,
    "name": "Other",
    "surname": "Seller",
    "email": email,
    "password": password,
    "isActive": True,
    "lockoutEnabled": True,
    "roleNames": []
}))
PY
)"
status="$(request_json POST '/api/identity/users' "$TOKEN" "$OTHER_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Second Seller create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
OTHER_TOKEN="$(get_fixture_token "$OTHER_USER" "$OTHER_PASSWORD")"
status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$OTHER_TOKEN")"
[[ "$status" == "403" ]] || { echo "Cross-Seller publish expected 403, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json POST "/api/app/listing-photo/attach/$LISTING_ID" "$OTHER_TOKEN" "$(attach_body "$MEDIA_2")")"
[[ "$status" == "403" ]] || { echo "Cross-Seller attach expected 403, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "SELLER_PUBLISH_OWNERSHIP: PASS"

status="$(request_json GET "/api/app/public-listing/$LISTING_ID")"
[[ "$status" == "204" || "$status" == "404" ]] || { echo "Draft public detail expected hidden, got $status" >&2; exit 1; }

echo "SELLER_PUBLISH_DRAFT_PRIVATE_API: PASS"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_AUTHORITY="$API_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_AUTHORITY="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$WEB_BASE" -o "$HOME_HTML"; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE" -o "$HOME_HTML" || { cat "$WEB_LOG" >&2; exit 1; }
if grep -Fq "$LISTING_TITLE" "$HOME_HTML"; then
  echo "Draft leaked into public Next list" >&2
  exit 1
fi
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Draft Next detail expected 404, got $status" >&2; exit 1; }
echo "SELLER_PUBLISH_DRAFT_PRIVATE_WEB: PASS"

status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Published":
    raise SystemExit(f"Publish did not return Published: {data}")
PY
curl --fail --silent --show-error "$WEB_BASE" -o "$HOME_HTML"
grep -Fq "$LISTING_TITLE" "$HOME_HTML" || { echo "Published Listing missing from Next list" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Published Next detail expected 200, got $status" >&2; exit 1; }
grep -Fq "/api/app/public-listing/$LISTING_ID/photo/$PHOTO_2" "$DETAIL_HTML" || { echo "Published detail missing remaining photo" >&2; exit 1; }
status="$(curl --silent --show-error --output "$PUBLIC_PHOTO" --write-out '%{http_code}' "$API_BASE/api/app/public-listing/$LISTING_ID/photo/$PHOTO_2")"
[[ "$status" == "200" ]] || { echo "Published photo expected 200, got $status" >&2; exit 1; }
cmp -s "$PNG" "$PUBLIC_PHOTO" || { echo "Published photo bytes differ from upload" >&2; exit 1; }
echo "SELLER_PUBLISH_PUBLIC: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Paused Next detail expected 404, got $status" >&2; exit 1; }
echo "SELLER_PUBLISH_PAUSE: PASS"

status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Republish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Republished Next detail expected 200, got $status" >&2; exit 1; }
echo "SELLER_PUBLISH_REPUBLISH: PASS"

status="$(request_json POST "/api/app/listing-command/archive/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Archive failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Archived Next detail expected 404, got $status" >&2; exit 1; }
echo "SELLER_PUBLISH_ARCHIVE: PASS"

echo "SELLER PHOTOS PUBLISH HTTP: PASSED"
