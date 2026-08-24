#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5093}"
WEB_PORT="${BPT_PUBLIC_WEB_PORT:-3093}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
API_LOG="${TMPDIR:-/tmp}/bpt2-public-buyer-api.log"
WEB_LOG="${TMPDIR:-/tmp}/bpt2-public-buyer-web.log"
RESPONSE="${TMPDIR:-/tmp}/bpt2-public-buyer-response.json"
HOME_HTML="${TMPDIR:-/tmp}/bpt2-public-buyer-home.html"
DETAIL_HTML="${TMPDIR:-/tmp}/bpt2-public-buyer-detail.html"
PHOTO_RESPONSE="${TMPDIR:-/tmp}/bpt2-public-buyer-photo.bin"
CONTACT_HEADERS="${TMPDIR:-/tmp}/bpt2-public-buyer-contact-headers.txt"
SWAGGER="${TMPDIR:-/tmp}/bpt2-public-buyer-swagger.json"
PNG="${TMPDIR:-/tmp}/bpt2-public-buyer.png"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export BPT_MEDIA_ROOT="${BPT_MEDIA_ROOT:-${TMPDIR:-/tmp}/bpt2-public-buyer-media}"
rm -rf "$BPT_MEDIA_ROOT"
mkdir -p "$BPT_MEDIA_ROOT"

printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

BACKEND_PID=""
WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$BACKEND_PID" ]] || kill "$BACKEND_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" url="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$url"
}

get_token() {
  local token_file="${TMPDIR:-/tmp}/bpt2-public-buyer-token.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Admin token expected 200, got $status: $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Token response did not contain access_token")
print(token)
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
BACKEND_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    cat "$API_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER" || { cat "$API_LOG" >&2; exit 1; }
python3 - "$SWAGGER" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
operations = data.get("paths", {}).get("/api/app/lead", {})
if "post" not in operations:
    raise SystemExit(f"Expected conventional POST /api/app/lead route, got: {operations}")
PY
echo "PUBLIC_LEAD_ROUTE: PASS"

ADMIN_TOKEN="$(get_token)"
EXPECTED_WHATSAPP="5511999998877"
SELLER_NAME="BPT Public Seller"
SELLER_PROFILE_BODY='{"displayName":"BPT Public Seller","whatsAppNumber":"+55 (11) 99999-8877"}'
status="$(request_json POST "$API_BASE/api/app/seller-profile/upsert" "$ADMIN_TOKEN" "$SELLER_PROFILE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile upsert expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$EXPECTED_WHATSAPP" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("whatsAppNumber") != sys.argv[2]:
    raise SystemExit(f"Seller WhatsApp was not normalized: {data}")
PY

status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
  -X POST "$API_BASE/api/app/media-upload/upload" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "content=@${PNG};type=image/png")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Media upload expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["id"])
PY
)"

LISTING_TITLE="Public Buyer HTTP Listing"
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$LISTING_TITLE" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": sys.argv[2],
    "price": 149900,
    "description": "Anúncio comprovado pelo fluxo HTTP real do public web.",
    "manufactureYear": 2024,
    "mileageKm": 12000,
    "color": "Preto",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json POST "$API_BASE/api/app/listing-command" "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft":
    raise SystemExit(f"Listing must start Draft: {data}")
print(data["id"])
PY
)"

status="$(request_json POST "$API_BASE/api/app/lead?listingId=$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Draft Lead create expected 404, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "PUBLIC_LEAD_DRAFT_BLOCKED: PASS"

ATTACH_BODY="$(python3 - "$MEDIA_ID" <<'PY'
import json, sys
print(json.dumps({"mediaAssetId": sys.argv[1]}))
PY
)"
status="$(request_json POST "$API_BASE/api/app/listing-photo/attach/$LISTING_ID" "$ADMIN_TOKEN" "$ATTACH_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing photo attach expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_ID="$(python3 - "$RESPONSE" "$MEDIA_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    photos = json.load(handle)
media_id = sys.argv[2].lower()
photo = next((item for item in photos if str(item.get("mediaAssetId", "")).lower() == media_id), None)
if photo is None:
    raise SystemExit(f"Attached photo missing: {photos}")
print(photo["id"])
PY
)"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
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
  echo "Draft Listing leaked into public web list." >&2
  exit 1
fi
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Draft Listing public detail expected 404, got $status" >&2; exit 1; }
if grep -Fq "property=\"og:url\" content=\"$WEB_BASE/anuncios/$LISTING_ID\"" "$DETAIL_HTML"; then
  echo "Draft Listing leaked social URL metadata." >&2
  exit 1
fi
echo "PUBLIC_WEB_DRAFT_PRIVATE: PASS"

status="$(request_json POST "$API_BASE/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Listing publish expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request_json POST "$API_BASE/api/app/lead?listingId=$LISTING_ID")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Published Lead create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if str(data.get("listingId", "")).lower() != sys.argv[2].lower():
    raise SystemExit(f"Lead ListingId mismatch: {data}")
if data.get("channel") != "WhatsApp":
    raise SystemExit(f"Lead channel mismatch: {data}")
if data.get("userId") is not None:
    raise SystemExit(f"Anonymous Lead unexpectedly has UserId: {data}")
if not data.get("id") or not data.get("createdAtUtc"):
    raise SystemExit(f"Persisted Lead result incomplete: {data}")
PY
echo "PUBLIC_LEAD_PERSISTED: PASS"

curl --fail --silent --show-error "$WEB_BASE" -o "$HOME_HTML"
grep -Fq "$LISTING_TITLE" "$HOME_HTML" || { echo "Published Listing missing from public web list." >&2; exit 1; }
grep -Fq "/anuncios/$LISTING_ID" "$HOME_HTML" || { echo "Published Listing detail link missing from public web list." >&2; exit 1; }
echo "PUBLIC_WEB_LIST: PASS"

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Published Listing detail expected 200, got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }

grep -Fq "$LISTING_TITLE" "$DETAIL_HTML" || { echo "Detail title missing." >&2; exit 1; }
grep -Fq "$SELLER_NAME" "$DETAIL_HTML" || { echo "Seller display name missing." >&2; exit 1; }
grep -Fq "HTTP Lifecycle Model" "$DETAIL_HTML" || { echo "Vehicle model missing." >&2; exit 1; }
grep -Fq "HTTP Lifecycle Version" "$DETAIL_HTML" || { echo "Vehicle version missing." >&2; exit 1; }
grep -Fq 'action="/api/contact/whatsapp"' "$DETAIL_HTML" || { echo "Lead-capturing WhatsApp form missing." >&2; exit 1; }
grep -Fq "value=\"$LISTING_ID\"" "$DETAIL_HTML" || { echo "WhatsApp form ListingId missing." >&2; exit 1; }
grep -Fq "/api/app/public-listing/$LISTING_ID/photo/$PHOTO_ID" "$DETAIL_HTML" || { echo "Public photo URL missing from detail." >&2; exit 1; }
grep -Fq "<title>$LISTING_TITLE | Bom Pra Ti</title>" "$DETAIL_HTML" || { echo "Listing metadata title missing." >&2; exit 1; }
echo "PUBLIC_WEB_DETAIL: PASS"
echo "PUBLIC_WEB_METADATA: PASS"

python3 - "$DETAIL_HTML" "$LISTING_TITLE" "$WEB_BASE/anuncios/$LISTING_ID" "$API_BASE/api/app/public-listing/$LISTING_ID/photo/$PHOTO_ID" <<'PY'
from html.parser import HTMLParser
import sys

class MetaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.meta = []
        self.links = []
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "meta":
            self.meta.append(values)
        elif tag == "link":
            self.links.append(values)

parser = MetaParser()
with open(sys.argv[1], encoding="utf-8") as handle:
    parser.feed(handle.read())

def meta(key, value):
    for item in parser.meta:
        if item.get(key) == value:
            return item.get("content")
    return None

title, canonical, image = sys.argv[2:5]
description = meta("name", "description")
if not description:
    raise SystemExit("Normal description metadata missing")
if meta("property", "og:title") != title:
    raise SystemExit(f"Open Graph title mismatch: {meta('property', 'og:title')!r}")
if meta("property", "og:description") != description:
    raise SystemExit("Open Graph description diverged from normal description")
if meta("property", "og:url") != canonical:
    raise SystemExit(f"Open Graph URL mismatch: {meta('property', 'og:url')!r}")
if meta("property", "og:image") != image:
    raise SystemExit(f"Open Graph image mismatch: {meta('property', 'og:image')!r}")
if meta("name", "twitter:card") != "summary_large_image":
    raise SystemExit(f"Twitter card mismatch: {meta('name', 'twitter:card')!r}")
if meta("name", "twitter:title") != title:
    raise SystemExit("Twitter title mismatch")
if meta("name", "twitter:description") != description:
    raise SystemExit("Twitter description diverged from normal description")
if meta("name", "twitter:image") != image:
    raise SystemExit(f"Twitter image mismatch: {meta('name', 'twitter:image')!r}")
canonical_link = next((x.get("href") for x in parser.links if x.get("rel") == "canonical"), None)
if canonical_link != canonical:
    raise SystemExit(f"Canonical mismatch: {canonical_link!r}")
PY
echo "PUBLIC_WEB_SHARE_METADATA: PASS"

status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$CONTACT_HEADERS" --write-out '%{http_code}' \
  -X POST "$WEB_BASE/api/contact/whatsapp" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "listingId=$LISTING_ID")"
[[ "$status" == "303" ]] || { echo "WhatsApp contact route expected 303, got $status: $(cat "$RESPONSE")" >&2; cat "$CONTACT_HEADERS" >&2; exit 1; }
tr -d '\r' < "$CONTACT_HEADERS" | grep -Fqi "location: https://wa.me/$EXPECTED_WHATSAPP" || { echo "WhatsApp contact route did not redirect to canonical Seller number." >&2; cat "$CONTACT_HEADERS" >&2; exit 1; }
echo "PUBLIC_WEB_WHATSAPP_LEAD: PASS"

status="$(curl --silent --show-error --output "$PHOTO_RESPONSE" --write-out '%{http_code}' "$API_BASE/api/app/public-listing/$LISTING_ID/photo/$PHOTO_ID")"
[[ "$status" == "200" ]] || { echo "Public photo expected 200, got $status" >&2; exit 1; }
cmp -s "$PNG" "$PHOTO_RESPONSE" || { echo "Public web photo target differs from uploaded bytes." >&2; exit 1; }
echo "PUBLIC_WEB_PHOTO: PASS"

status="$(request_json POST "$API_BASE/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Listing pause expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json POST "$API_BASE/api/app/lead?listingId=$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Paused Lead create expected 404, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Paused Listing public detail expected 404, got $status" >&2; exit 1; }
if grep -Fq "property=\"og:url\" content=\"$WEB_BASE/anuncios/$LISTING_ID\"" "$DETAIL_HTML"; then
  echo "Paused Listing retained social URL metadata." >&2
  exit 1
fi
echo "PUBLIC_LEAD_PAUSED_BLOCKED: PASS"
echo "PUBLIC_WEB_SHARE_METADATA_PAUSED_PRIVATE: PASS"

status="$(request_json POST "$API_BASE/api/app/listing-command/archive/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Listing archive expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json POST "$API_BASE/api/app/lead?listingId=$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Archived Lead create expected 404, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "PUBLIC_LEAD_ARCHIVED_BLOCKED: PASS"

echo "PUBLIC BUYER HTTP FLOW: PASSED"