#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_STRUCTURED_DATA_API_PORT:-5094}"
WEB_PORT="${BPT_STRUCTURED_DATA_WEB_PORT:-3094}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-listing-structured-data"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
RESPONSE="$TMP/response.json"
PUBLIC_JSON="$TMP/public-listing.json"
DRAFT_HTML="$TMP/draft.html"
DETAIL_HTML="$TMP/detail.html"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false

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

get_admin_token() {
  local token_file="$TMP/token.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Admin token failed: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['access_token'])
PY
}

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null; then
    break
  fi
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then
    cat "$API_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_admin_token)"
status="$(request_json POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Structured Data Seller","whatsAppNumber":"5511999994444"}')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    'vehicleId': sys.argv[1],
    'title': 'Structured Data Listing',
    'price': 123456.78,
    'description': 'JSON-LD safety </script><script id="jsonld-breakout">x</script>',
    'manufactureYear': 2024,
    'mileageKm': 54321,
    'color': 'Azul',
    'city': 'Curitiba',
    'stateCode': 'PR'
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"

pushd "$ROOT/public-web" >/dev/null
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$WEB_BASE/" >/dev/null; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE/" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

status="$(curl --silent --show-error --output "$DRAFT_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Draft detail expected 404, got $status" >&2; exit 1; }
if grep -Fq 'application/ld+json' "$DRAFT_HTML"; then
  echo 'Draft detail exposed structured data.' >&2
  exit 1
fi
echo 'PUBLIC_LISTING_STRUCTURED_DATA_DRAFT_EXCLUDED: PASS'

status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json GET "/api/app/public-listing/$LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Public Listing fetch failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
cp "$RESPONSE" "$PUBLIC_JSON"

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Published detail expected 200, got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }

python3 - "$DETAIL_HTML" "$PUBLIC_JSON" "$WEB_BASE/anuncios/$LISTING_ID" <<'PY'
from html.parser import HTMLParser
from decimal import Decimal
import json, sys

class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_jsonld = False
        self.current = []
        self.jsonld = []
        self.breakout_script = False
        self.visible = []
    def handle_starttag(self, tag, attrs):
        data = dict(attrs)
        if tag == 'script' and data.get('id') == 'jsonld-breakout':
            self.breakout_script = True
        if tag == 'script' and data.get('type') == 'application/ld+json':
            self.in_jsonld = True
            self.current = []
    def handle_endtag(self, tag):
        if tag == 'script' and self.in_jsonld:
            self.jsonld.append(''.join(self.current))
            self.in_jsonld = False
    def handle_data(self, data):
        if self.in_jsonld:
            self.current.append(data)
        else:
            self.visible.append(data)

html = open(sys.argv[1], encoding='utf-8').read()
api = json.load(open(sys.argv[2], encoding='utf-8'))
canonical = sys.argv[3]
parser = Parser(); parser.feed(html)
if parser.breakout_script:
    raise SystemExit('Seller-controlled description created a breakout script')
if len(parser.jsonld) != 1:
    raise SystemExit(f'Expected exactly one JSON-LD block, got {len(parser.jsonld)}')
if '<script id="jsonld-breakout">' in html:
    raise SystemExit('Unsafe raw breakout payload remained in rendered HTML')

data = json.loads(parser.jsonld[0])
if data.get('@context') != 'https://schema.org':
    raise SystemExit(f'Unexpected JSON-LD context: {data.get("@context")!r}')
if set(data.get('@type', [])) != {'Product', 'Vehicle'}:
    raise SystemExit(f'Unexpected JSON-LD types: {data.get("@type")!r}')
expected = {
    'name': api['title'],
    'description': api['description'],
    'url': canonical,
    'model': api['vehicle']['model'],
    'vehicleConfiguration': api['vehicle']['version'],
    'color': api['color'],
}
for key, value in expected.items():
    if data.get(key) != value:
        raise SystemExit(f'{key} mismatch: expected {value!r}, got {data.get(key)!r}')
if data.get('brand') != {'@type': 'Brand', 'name': api['vehicle']['brand']}:
    raise SystemExit(f'Brand mismatch: {data.get("brand")!r}')
if data.get('mileageFromOdometer') != {'@type': 'QuantitativeValue', 'value': api['mileageKm'], 'unitCode': 'KMT'}:
    raise SystemExit(f'Mileage mismatch: {data.get("mileageFromOdometer")!r}')
if 'image' in data:
    raise SystemExit(f'Image must be omitted for no-photo fixture: {data["image"]!r}')
offer = data.get('offers') or {}
if offer.get('@type') != 'Offer' or offer.get('url') != canonical:
    raise SystemExit(f'Offer identity mismatch: {offer!r}')
if Decimal(str(offer.get('price'))) != Decimal(str(api['price'])):
    raise SystemExit(f'Offer price mismatch: {offer.get("price")!r} vs {api["price"]!r}')
if offer.get('priceCurrency') != 'BRL' or offer.get('availability') != 'https://schema.org/InStock':
    raise SystemExit(f'Offer currency/availability mismatch: {offer!r}')
for forbidden in ('aggregateRating', 'review', 'sku', 'mpn', 'itemCondition', 'vehicleIdentificationNumber', 'seller'):
    if forbidden in data:
        raise SystemExit(f'Invented structured-data property present: {forbidden}')
visible = ''.join(parser.visible)
if 'R$' not in visible or '123.456,78' not in visible:
    raise SystemExit('Visible price did not preserve the same cent value as the Offer')
PY
echo 'PUBLIC_LISTING_STRUCTURED_DATA_PUBLISHED: PASS'
echo 'PUBLIC_LISTING_STRUCTURED_DATA_SAFE_SERIALIZATION: PASS'
echo 'PUBLIC_LISTING_STRUCTURED_DATA_PRICE_COHERENCE: PASS'

status="$(request_json POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$DRAFT_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == "404" ]] || { echo "Paused detail expected 404, got $status" >&2; exit 1; }
if grep -Fq 'application/ld+json' "$DRAFT_HTML"; then
  echo 'Paused detail exposed structured data.' >&2
  exit 1
fi
echo 'PUBLIC_LISTING_STRUCTURED_DATA_PAUSED_EXCLUDED: PASS'

echo 'PUBLIC LISTING STRUCTURED DATA HTTP: PASSED'
