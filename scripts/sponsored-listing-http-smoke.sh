#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5107}"
WEB_PORT="${BPT_SPONSORED_WEB_PORT:-3107}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-sponsored-listing"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
RESPONSE="$TMP/response.json"

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

get_token() {
  local token_file="$TMP/token.json" status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token failed: $status" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['access_token'])
PY
}

create_listing() {
  local title="$1" price="$2" body status
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId': sys.argv[1], 'title': sys.argv[2], 'price': float(sys.argv[3]),
  'description': 'Sponsored contract fixture.', 'manufactureYear': 2024,
  'mileageKm': 10000, 'color': 'Prata', 'city': 'São Paulo', 'stateCode': 'SP'
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
}

publish_listing() {
  local status
  status="$(request_json POST "/api/app/listing-command/publish/$1" "$ADMIN_TOKEN")"
  [[ "$status" == "200" ]] || { echo "Publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
}

snapshot_ids() {
  local sort="$1" out="$2" url="$API_BASE/api/app/public-listing?Query=Sponsored%20Contract&Skip=0&Take=10"
  [[ -z "$sort" ]] || url="$url&Sort=$sort"
  curl --fail --silent --show-error "$url" -o "$out"
  python3 - "$out" <<'PY'
import json,sys
print('|'.join(item['id'] for item in json.load(open(sys.argv[1], encoding='utf-8'))['items']))
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null && break
  kill -0 "$API_PID" >/dev/null 2>&1 || { cat "$API_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null

ADMIN_TOKEN="$(get_token)"
status="$(request_json POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Sponsored Contract Seller","whatsAppNumber":"5511999999999"}')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

ACTIVE_ID="$(create_listing 'Sponsored Contract Active' 300000)"
FUTURE_ID="$(create_listing 'Sponsored Contract Future' 100000)"
EXPIRED_ID="$(create_listing 'Sponsored Contract Expired' 200000)"
DRAFT_ID="$(create_listing 'Sponsored Contract Draft' 400000)"
publish_listing "$ACTIVE_ID"
publish_listing "$FUTURE_ID"
publish_listing "$EXPIRED_ID"

BEFORE_DEFAULT="$(snapshot_ids '' "$TMP/before-default.json")"
BEFORE_ASC="$(snapshot_ids 'price-asc' "$TMP/before-asc.json")"
BEFORE_DESC="$(snapshot_ids 'price-desc' "$TMP/before-desc.json")"
python3 - "$TMP/before-default.json" "$DRAFT_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1], encoding='utf-8'))['items']
assert len(items)==3, items
assert sys.argv[2] not in {x['id'] for x in items}
assert all(x.get('isSponsored') is False for x in items), items
PY
echo "SPONSORED_BASELINE_PUBLIC_ONLY: PASS"

dotnet run --project "$ROOT/tests/BomPraTi.HttpLifecycleFixture/BomPraTi.HttpLifecycleFixture.csproj" --configuration Release -- promotion "$ACTIVE_ID" active >/dev/null
dotnet run --project "$ROOT/tests/BomPraTi.HttpLifecycleFixture/BomPraTi.HttpLifecycleFixture.csproj" --configuration Release -- promotion "$FUTURE_ID" future >/dev/null
dotnet run --project "$ROOT/tests/BomPraTi.HttpLifecycleFixture/BomPraTi.HttpLifecycleFixture.csproj" --configuration Release -- promotion "$EXPIRED_ID" expired >/dev/null
dotnet run --project "$ROOT/tests/BomPraTi.HttpLifecycleFixture/BomPraTi.HttpLifecycleFixture.csproj" --configuration Release -- promotion "$DRAFT_ID" active >/dev/null

AFTER_DEFAULT="$(snapshot_ids '' "$TMP/after-default.json")"
AFTER_ASC="$(snapshot_ids 'price-asc' "$TMP/after-asc.json")"
AFTER_DESC="$(snapshot_ids 'price-desc' "$TMP/after-desc.json")"
[[ "$BEFORE_DEFAULT" == "$AFTER_DEFAULT" ]] || { echo "Default organic order changed" >&2; exit 1; }
[[ "$BEFORE_ASC" == "$AFTER_ASC" ]] || { echo "price-asc organic order changed" >&2; exit 1; }
[[ "$BEFORE_DESC" == "$AFTER_DESC" ]] || { echo "price-desc organic order changed" >&2; exit 1; }
echo "SPONSORED_ORGANIC_ORDER_INVARIANT: PASS"

python3 - "$TMP/after-default.json" "$ACTIVE_ID" "$FUTURE_ID" "$EXPIRED_ID" "$DRAFT_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1], encoding='utf-8'))['items']
by_id={x['id']: x for x in items}
active,future,expired,draft=sys.argv[2:]
assert by_id[active]['isSponsored'] is True, by_id[active]
assert by_id[future]['isSponsored'] is False, by_id[future]
assert by_id[expired]['isSponsored'] is False, by_id[expired]
assert draft not in by_id, by_id
PY
echo "SPONSORED_TIME_WINDOW: PASS"

status="$(request_json GET "/api/app/public-listing/$DRAFT_ID")"
[[ "$status" == "404" || "$status" == "204" ]] || { echo "Draft promotion leaked via detail: $status" >&2; exit 1; }
echo "SPONSORED_DRAFT_HIDDEN: PASS"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$WEB_BASE/?query=Sponsored%20Contract" -o "$TMP/page.html" && break
  kill -0 "$WEB_PID" >/dev/null 2>&1 || { cat "$WEB_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE/?query=Sponsored%20Contract" -o "$TMP/page.html"
python3 - "$TMP/page.html" <<'PY'
from html.parser import HTMLParser
import sys

class P(HTMLParser):
    ignored = {'script', 'style', 'template', 'noscript'}

    def __init__(self):
        super().__init__()
        self.parts=[]
        self.depth=0

    def handle_starttag(self, tag, attrs):
        if tag in self.ignored:
            self.depth += 1

    def handle_endtag(self, tag):
        if tag in self.ignored and self.depth:
            self.depth -= 1

    def handle_data(self, data):
        if self.depth == 0:
            self.parts.append(data)

p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read()); text=' '.join(p.parts)
if text.count('Patrocinado') != 1:
    raise SystemExit(f"Expected one visible Patrocinado label, got {text.count('Patrocinado')}")
if 'Sponsored Contract Active' not in text:
    raise SystemExit('Active sponsored Listing missing from public web')
PY
echo "SPONSORED_PUBLIC_LABEL: PASS"
echo "SPONSORED LISTING HTTP: PASSED"
