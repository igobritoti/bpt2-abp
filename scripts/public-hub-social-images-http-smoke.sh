#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_HUB_SOCIAL_API_PORT:-5110}"
WEB_PORT="${BPT_HUB_SOCIAL_WEB_PORT:-3110}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-hub-social-images"
RESPONSE="$TMP/response.json"
HTML="$TMP/page.html"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
PNG="$TMP/social.png"

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
export BPT_MEDIA_ROOT="$TMP/media"
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
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$API_BASE$path"
}

get_token() {
  curl --silent --show-error -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

assert_social_image() {
  local file="$1" expected="$2"
  python3 - "$file" "$expected" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    def __init__(self): super().__init__(); self.meta=[]
    def handle_starttag(self, tag, attrs):
        if tag == 'meta': self.meta.append(dict(attrs))
p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read())
def meta(key, value):
    for item in p.meta:
        if item.get(key) == value: return item.get('content')
    return None
expected=sys.argv[2]
actual=(meta('property','og:image'), meta('name','twitter:image'), meta('name','twitter:card'))
if actual != (expected, expected, 'summary_large_image'):
    raise SystemExit(f'Social image metadata mismatch: expected {expected!r}, got {actual!r}')
PY
}

assert_no_social_image() {
  local file="$1"
  python3 - "$file" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    def __init__(self): super().__init__(); self.meta=[]
    def handle_starttag(self, tag, attrs):
        if tag == 'meta': self.meta.append(dict(attrs))
p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read())
def meta(key, value):
    for item in p.meta:
        if item.get(key) == value: return item.get('content')
    return None
actual=(meta('property','og:image'), meta('name','twitter:image'), meta('name','twitter:card'))
if actual != (None, None, 'summary'):
    raise SystemExit(f'No-image metadata mismatch: {actual!r}')
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null && break
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then cat "$API_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_token)"
status="$(request_json POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Hub Social Seller","whatsAppNumber":"+55 (11) 97777-6655"}')"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Seller profile failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
SELLER_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId':sys.argv[1], 'title':'Public Hub Social Image Listing', 'price':155900,
  'description':'Fixture para metadata social dos hubs públicos.', 'manufactureYear':2024,
  'mileageKm':12000, 'color':'Azul', 'city':'São Paulo', 'stateCode':'SP'
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8')); assert data['status']=='Draft',data; print(data['id'])
PY
)"

status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
  -X POST "$API_BASE/api/app/media-upload/upload" -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "content=@${PNG};type=image/png")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Media upload failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"
ATTACH_BODY="$(python3 - "$MEDIA_ID" <<'PY'
import json,sys
print(json.dumps({'mediaAssetId':sys.argv[1]}))
PY
)"
status="$(request_json POST "/api/app/listing-photo/attach/$LISTING_ID" "$ADMIN_TOKEN" "$ATTACH_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Photo attach failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_ID="$(python3 - "$RESPONSE" "$MEDIA_ID" <<'PY'
import json,sys
photos=json.load(open(sys.argv[1], encoding='utf-8')); media=sys.argv[2].lower()
photo=next((x for x in photos if str(x.get('mediaAssetId','')).lower()==media),None)
if not photo: raise SystemExit(f'Attached photo missing: {photos}')
print(photo['id'])
PY
)"

status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
SOCIAL_IMAGE="$API_BASE/api/app/public-listing/$LISTING_ID/photo/$PHOTO_ID"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$WEB_BASE" >/dev/null && break
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then cat "$WEB_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

status="$(curl --silent --show-error --output "$HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$SELLER_ID")"
[[ "$status" == 200 ]] || { echo "Seller Hub expected 200, got $status" >&2; exit 1; }
assert_social_image "$HTML" "$SOCIAL_IMAGE"
echo 'PUBLIC_SELLER_HUB_SOCIAL_IMAGE: PASS'

status="$(curl --silent --show-error --output "$HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Vehicle Hub expected 200, got $status" >&2; exit 1; }
assert_social_image "$HTML" "$SOCIAL_IMAGE"
echo 'PUBLIC_VEHICLE_HUB_SOCIAL_IMAGE: PASS'

status="$(request_json POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Vehicle Hub after pause expected 200, got $status" >&2; exit 1; }
assert_no_social_image "$HTML"
echo 'PUBLIC_VEHICLE_HUB_SOCIAL_IMAGE_REMOVED_AFTER_PAUSE: PASS'

echo 'PUBLIC HUB SOCIAL IMAGES HTTP: PASSED'
