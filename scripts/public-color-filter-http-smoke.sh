#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_COLOR_FILTER_API_PORT:-5107}"
WEB_PORT="${BPT_COLOR_FILTER_WEB_PORT:-3107}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-color-filter"
RESPONSE="$TMP/response.json"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
PAGE="$TMP/page.html"

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
  local title="$1" color="$2" city="$3" body status listing_id
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$color" "$city" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId': sys.argv[1],
  'title': sys.argv[2],
  'price': 123000,
  'description': 'Fixture de filtro público por cor.',
  'manufactureYear': 2024,
  'mileageKm': 12000,
  'color': sys.argv[3],
  'city': sys.argv[4],
  'stateCode': 'SP'
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "Color fixture create failed $status: $(cat "$RESPONSE")" >&2; return 1; }
  listing_id="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$ADMIN_TOKEN")"
  [[ "$status" == 200 ]] || { echo "Color fixture publish failed $status: $(cat "$RESPONSE")" >&2; return 1; }
}

[[ -f "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" ]] || { echo 'Host Release build missing; Public Discovery smoke must run first.' >&2; exit 1; }
[[ -d "$ROOT/public-web/.next" ]] || { echo 'Next production build missing; Public Discovery smoke must run first.' >&2; exit 1; }

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break
  kill -0 "$API_PID" >/dev/null 2>&1 || { cat "$API_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_token)"
SILVER_TITLE='Color Filter Silver'
BLACK_TITLE='Color Filter Black'
OTHER_CITY_TITLE='Color Filter Silver Other City'
create_and_publish "$SILVER_TITLE" ' Prata ' 'São Paulo'
create_and_publish "$BLACK_TITLE" 'Preto' 'São Paulo'
create_and_publish "$OTHER_CITY_TITLE" 'PRATA' 'Campinas'
echo 'PUBLIC_COLOR_FILTER_FIXTURES: PASS'

status="$(request_json GET '/api/app/public-listing?Query=Color%20Filter&Color=prata&Take=10')"
[[ "$status" == 200 ]] || { echo "Color API expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$SILVER_TITLE" "$OTHER_CITY_TITLE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
titles={item['title'] for item in x['items']}
assert x['totalCount']==2,x
assert titles=={sys.argv[2],sys.argv[3]},titles
assert all((item.get('color') or '').strip().lower()=='prata' for item in x['items']),x
print('PUBLIC_COLOR_FILTER_API_NORMALIZED_EQUALITY: PASS')
PY

status="$(request_json GET '/api/app/public-listing?Query=Color%20Filter&Color=PRATA&City=S%C3%A3o%20Paulo&Take=10')"
[[ "$status" == 200 ]] || { echo "Combined color API expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$SILVER_TITLE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
assert x['totalCount']==1,x
assert [item['title'] for item in x['items']]==[sys.argv[2]],x
print('PUBLIC_COLOR_FILTER_API_COMPOSITION: PASS')
PY

pushd "$ROOT/public-web" >/dev/null
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent "$WEB_BASE/?query=Color%20Filter&color=prata&city=S%C3%A3o%20Paulo&take=1" -o "$PAGE" && break
  kill -0 "$WEB_PID" >/dev/null 2>&1 || { cat "$WEB_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$WEB_BASE/?query=Color%20Filter&color=prata&city=S%C3%A3o%20Paulo&take=1" -o "$PAGE" || { cat "$WEB_LOG" >&2; exit 1; }
python3 - "$PAGE" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    found=False; value=None
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if tag=='input' and values.get('name')=='color':
            self.found=True; self.value=values.get('value','')
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
if not p.found: raise SystemExit('Discovery form missing color control.')
if p.value!='prata': raise SystemExit(f'Color selection not preserved in SSR: {p.value!r}')
PY
grep -Fq "$SILVER_TITLE" "$PAGE" || { echo 'Color SSR missing matching listing.' >&2; exit 1; }
if grep -Fq "$BLACK_TITLE" "$PAGE" || grep -Fq "$OTHER_CITY_TITLE" "$PAGE"; then
  echo 'Color SSR leaked a non-matching fixture.' >&2; exit 1
fi
echo 'PUBLIC_COLOR_FILTER_SSR_ROUND_TRIP: PASS'

echo 'PUBLIC COLOR FILTER HTTP: PASSED'
