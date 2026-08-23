#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5095}"
BASE="http://127.0.0.1:${PORT}"
WEB_ROOT="${BPT_SELLER_WEB_ROOT:-http://localhost:3000}"
CLIENT_ID="BomPraTi_SellerWeb"
REDIRECT_URI="${WEB_ROOT}/vender/callback"
LOGOUT_REDIRECT_URI="${WEB_ROOT}/vender"
TMP="${TMPDIR:-/tmp}/bpt2-seller-shell"
LOG="${TMP}/api.log"
RESPONSE="${TMP}/response.json"
HEADERS="${TMP}/headers.txt"
COOKIES="${TMP}/cookies.txt"
LOGIN_HTML="${TMP}/login.html"
TOKEN_JSON="${TMP}/token.json"
DISCOVERY="${TMP}/discovery.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false
export OpenIddict__Applications__BomPraTi_SellerWeb__RootUrl="$WEB_ROOT"

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$BASE/.well-known/openid-configuration" -o "$DISCOVERY"; then
    break
  fi
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$DISCOVERY" ]] || { cat "$LOG" >&2; echo "OIDC discovery did not become available." >&2; exit 1; }

python3 - "$DISCOVERY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for key in ("authorization_endpoint", "token_endpoint", "end_session_endpoint"):
    if not data.get(key):
        raise SystemExit(f"OIDC discovery missing {key}")
if "S256" not in data.get("code_challenge_methods_supported", []):
    raise SystemExit("OIDC discovery does not advertise S256 PKCE")
PY
echo "SELLER_SHELL_OIDC_DISCOVERY: PASS"

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
  python3 - "$BASE" "$1" <<'PY'
import sys
from urllib.parse import urljoin
print(urljoin(sys.argv[1] + "/", sys.argv[2]))
PY
}

read -r CODE_VERIFIER CODE_CHALLENGE STATE < <(python3 <<'PY'
import base64, hashlib, secrets
verifier = secrets.token_urlsafe(72)[:96]
challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
print(verifier, challenge, secrets.token_urlsafe(24))
PY
)

AUTH_URL="$(python3 - "$BASE" "$CLIENT_ID" "$REDIRECT_URI" "$CODE_CHALLENGE" "$STATE" <<'PY'
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
[[ "$status" == "302" ]] || { cat "$RESPONSE" >&2; echo "Seller authorize expected 302 to Account login, got $status" >&2; exit 1; }
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
if "error" in query:
    raise SystemExit(f"Authorization error: {query}")
print(query["code"][0], query["state"][0])
PY
)
[[ "$RETURNED_STATE" == "$STATE" ]] || { echo "OIDC state mismatch" >&2; exit 1; }

echo "SELLER_SHELL_ACCOUNT_LOGIN: PASS"

status="$(curl --silent --show-error --output "$TOKEN_JSON" --write-out '%{http_code}' \
  --request POST "$BASE/connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=authorization_code' \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "code=$AUTH_CODE" \
  --data-urlencode "redirect_uri=$REDIRECT_URI" \
  --data-urlencode "code_verifier=$CODE_VERIFIER")"
[[ "$status" == "200" ]] || { cat "$TOKEN_JSON" >&2; echo "Seller PKCE exchange expected 200, got $status" >&2; exit 1; }

read -r TOKEN ID_TOKEN < <(python3 - "$TOKEN_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if not data.get("access_token") or not data.get("id_token"):
    raise SystemExit(f"Token response missing access/id token: {data}")
print(data["access_token"], data["id_token"])
PY
)
echo "SELLER_SHELL_PKCE_TOKEN: PASS"

request_json() {
  local method="$1" path="$2" token="$3" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method" \
    -H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$BASE$path"
}

PROFILE_INPUT='{"displayName":"BPT Seller Shell","whatsAppNumber":"+55 (11) 98888-7766"}'
status="$(request_json POST '/api/app/seller-profile/upsert' "$TOKEN" "$PROFILE_INPUT")"
[[ "$status" == "200" || "$status" == "201" ]] || {
  echo "Seller profile upsert expected 200/201, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("displayName") != "BPT Seller Shell":
    raise SystemExit(f"Unexpected Seller displayName: {data}")
if data.get("whatsAppNumber") != "5511988887766":
    raise SystemExit(f"Seller WhatsApp was not canonicalized: {data}")
PY
echo "SELLER_SHELL_PROFILE_UPSERT: PASS"

status="$(request_json GET '/api/app/seller-profile/current' "$TOKEN")"
[[ "$status" == "200" ]] || {
  echo "Seller profile current expected 200, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("displayName") != "BPT Seller Shell" or data.get("whatsAppNumber") != "5511988887766":
    raise SystemExit(f"Seller current profile mismatch: {data}")
PY
echo "SELLER_SHELL_PROFILE_CURRENT: PASS"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": "Seller Shell Draft",
    "price": 135000,
    "description": "Draft created to prove the authenticated Seller shell query.",
    "manufactureYear": 2024,
    "mileageKm": 12000,
    "color": "Cinza",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || {
  echo "Seller Listing create expected 200/201, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft":
    raise SystemExit(f"New Seller Listing must be Draft: {data}")
if not data.get("concurrencyStamp"):
    raise SystemExit(f"New Seller Listing must carry concurrencyStamp: {data}")
print(data["id"])
PY
)"
echo "SELLER_SHELL_DRAFT_CREATE: PASS"

status="$(request_json GET '/api/app/seller-listing-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || {
  echo "My Listings expected 200, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json, sys
path, listing_id = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
if not isinstance(data, list):
    raise SystemExit(f"My Listings response must be an array: {data}")
match = next((item for item in data if str(item.get("id", "")).lower() == listing_id.lower()), None)
if match is None:
    raise SystemExit(f"Created Listing {listing_id} missing from My Listings: {data}")
if match.get("title") != "Seller Shell Draft" or match.get("status") != "Draft":
    raise SystemExit(f"My Listings projection mismatch: {match}")
if not match.get("concurrencyStamp"):
    raise SystemExit(f"My Listings did not preserve concurrencyStamp: {match}")
PY
echo "SELLER_SHELL_MY_LISTINGS: PASS"

END_SESSION_ENDPOINT="$(python3 - "$DISCOVERY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["end_session_endpoint"])
PY
)"
LOGOUT_URL="$(python3 - "$END_SESSION_ENDPOINT" "$ID_TOKEN" "$LOGOUT_REDIRECT_URI" <<'PY'
import secrets, sys
from urllib.parse import urlencode
endpoint, id_token, redirect = sys.argv[1:]
print(endpoint + "?" + urlencode({
    "id_token_hint": id_token,
    "post_logout_redirect_uri": redirect,
    "state": secrets.token_urlsafe(18),
}))
PY
)"
status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$LOGOUT_URL")"
[[ "$status" == "200" || "$status" == "302" ]] || { cat "$RESPONSE" >&2; echo "Seller end-session expected 200/302, got $status" >&2; exit 1; }
echo "SELLER_SHELL_LOGOUT_ENDPOINT: PASS"

echo "SELLER SHELL HTTP: PASSED"
