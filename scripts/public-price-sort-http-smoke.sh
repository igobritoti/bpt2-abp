#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_PRICE_SORT_API_PORT:-5105}"
WEB_PORT="${BPT_PRICE_SORT_WEB_PORT:-3105}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-price-sort"
RESPONSE="$TMP/response.json"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
PAGE="$TMP/page.html"
PAGE_TWO="$TMP/page-two.html"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false

API_PID=""; WEB_PID=""
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

create_and_publish() {
  local title="$1" price="$2" body status listing_id
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId': sys.argv[1],
  'title': sys.argv[2],
  'price': float(sys.argv[3]),
  'description': 'Fixture de ordenação pública por preço.',
  'manufactureYear': 2024,
  'mileageKm': 12000,
  'color': 'Prata',
  'city': 'São Paulo',
  'stateCode': 'SP'
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "Price-sort listing create failed $status: $(cat "$RESPONSE")" >&2; return 1; }
  listing_id="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$ADMIN_TOKEN")"
  [[ "$status" == 200 ]] || { echo "Price-sort publish failed $status: $(cat "$RESPONSE")" >&2; return 1; }
  printf '%s\n' "$listing_id"
}

[[ -f "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" ]] || {
  echo 'Host Release build missing; Public Discovery smoke must run first.' >&2; exit 1;
}
[[ -d "$ROOT/public-web/.next" ]] || {
  echo 'Next production build missing; Public Discovery smoke must run first.' >&2; exit 1;
}

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break
  kill -0 "$API_PID" >/dev/null 2>&1 || { cat "$API_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_token)"
LOW_TITLE='Price Sort Low'
MID_TITLE='Price Sort Mid'
HIGH_TITLE='Price Sort High'
create_and_publish "$LOW_TITLE" 111000 >/dev/null
create_and_publish "$MID_TITLE" 222000 >/dev/null
create_and_publish "$HIGH_TITLE" 333000 >/dev/null
echo 'PUBLIC_PRICE_SORT_FIXTURES: PASS'

status="$(request_json GET '/api/app/public-listing?Query=Price%20Sort&Sort=price-asc&Take=10')"
[[ "$status" == 200 ]] || { echo "Price asc API expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
items=x['items']
assert x['totalCount']==3, x
prices=[item['price'] for item in items]
assert prices==[111000,222000,333000], prices
print('PUBLIC_PRICE_SORT_API_ASC: PASS')
PY

status="$(request_json GET '/api/app/public-listing?Query=Price%20Sort&Sort=price-desc&Take=10')"
[[ "$status" == 200 ]] || { echo "Price desc API expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
prices=[item['price'] for item in x['items']]
assert prices==[333000,222000,111000], prices
print('PUBLIC_PRICE_SORT_API_DESC: PASS')
PY

pushd "$ROOT/public-web" >/dev/null
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent "$WEB_BASE/?query=Price%20Sort&sort=price-desc&take=1" -o "$PAGE" && break
  kill -0 "$WEB_PID" >/dev/null 2>&1 || { cat "$WEB_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$WEB_BASE/?query=Price%20Sort&sort=price-desc&take=1" -o "$PAGE" || { cat "$WEB_LOG" >&2; exit 1; }

grep -Fq 'name="sort"' "$PAGE" || { echo 'Discovery form missing sort control.' >&2; exit 1; }
grep -Fq 'value="price-desc" selected' "$PAGE" || { echo 'Discovery sort selection not preserved in SSR.' >&2; exit 1; }
grep -Fq "$HIGH_TITLE" "$PAGE" || { echo 'Descending SSR first page missing highest price.' >&2; exit 1; }
if grep -Fq "$MID_TITLE" "$PAGE" || grep -Fq "$LOW_TITLE" "$PAGE"; then
  echo 'Descending SSR first page leaked another price-sort fixture.' >&2; exit 1
fi

NEXT_HREF="$(python3 - "$PAGE" <<'PY'
from html.parser import HTMLParser
from urllib.parse import parse_qs,urlparse
import sys
class P(HTMLParser):
    current=None; href=None
    def handle_starttag(self,tag,attrs):
        if tag=='a': self.current=dict(attrs).get('href')
    def handle_endtag(self,tag):
        if tag=='a': self.current=None
    def handle_data(self,data):
        if self.current and 'Próxima' in data: self.href=self.current
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
if not p.href: raise SystemExit('Next link missing')
q=parse_qs(urlparse(p.href).query)
for key,value in {'query':['Price Sort'],'sort':['price-desc'],'take':['1'],'skip':['1']}.items():
    if q.get(key)!=value: raise SystemExit(f'{key} not preserved: {p.href}')
print(p.href)
PY
)"
curl --fail --silent "$WEB_BASE$NEXT_HREF" -o "$PAGE_TWO"
grep -Fq "$MID_TITLE" "$PAGE_TWO" || { echo 'Descending SSR second page missing middle price.' >&2; exit 1; }
if grep -Fq "$HIGH_TITLE" "$PAGE_TWO" || grep -Fq "$LOW_TITLE" "$PAGE_TWO"; then
  echo 'Descending SSR second page repeated/skipped ordering.' >&2; exit 1
fi
echo 'PUBLIC_PRICE_SORT_SSR_PAGINATION: PASS'

echo 'PUBLIC PRICE SORT HTTP: PASSED'
