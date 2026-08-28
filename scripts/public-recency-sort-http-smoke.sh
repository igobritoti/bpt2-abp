#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_RECENCY_SORT_API_PORT:-5110}"
WEB_PORT="${BPT_RECENCY_SORT_WEB_PORT:-3110}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-recency-sort"
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
  local title="$1" body status listing_id
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId': sys.argv[1],
  'title': sys.argv[2],
  'price': 199000,
  'description': 'Fixture de ordenação pública por primeira publicação.',
  'manufactureYear': 2024,
  'mileageKm': 12000,
  'color': 'Prata',
  'city': 'São Paulo',
  'stateCode': 'SP'
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "Recency listing create failed $status: $(cat "$RESPONSE")" >&2; return 1; }
  listing_id="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$ADMIN_TOKEN")"
  [[ "$status" == 200 ]] || { echo "Recency publish failed $status: $(cat "$RESPONSE")" >&2; return 1; }
  printf '%s\n' "$listing_id"
}

assert_recent_order() {
  local marker="$1" expected_first="$2" expected_second="$3" status
  status="$(request_json GET '/api/app/public-listing?Query=Recency%20Sort&Sort=recent-desc&Take=10')"
  [[ "$status" == 200 ]] || { echo "Recent sort API expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
  python3 - "$RESPONSE" "$expected_first" "$expected_second" "$marker" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
ids=[item['id'] for item in x['items']]
assert x['totalCount']==2, x
assert ids==[sys.argv[2],sys.argv[3]], ids
print(f'{sys.argv[4]}: PASS')
PY
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
OLDER_TITLE='Recency Sort Older'
NEWER_TITLE='Recency Sort Newer'
OLDER_ID="$(create_and_publish "$OLDER_TITLE")"
sleep 1
NEWER_ID="$(create_and_publish "$NEWER_TITLE")"
echo 'PUBLIC_RECENCY_SORT_FIXTURES: PASS'

assert_recent_order 'PUBLIC_RECENCY_SORT_API_FIRST_PUBLICATION' "$NEWER_ID" "$OLDER_ID"

status="$(request_json POST "/api/app/listing-command/pause/$OLDER_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Recency pause failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
sleep 1
status="$(request_json POST "/api/app/listing-command/publish/$OLDER_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Recency republish failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
assert_recent_order 'PUBLIC_RECENCY_SORT_REPUBLISH_NO_BUMP' "$NEWER_ID" "$OLDER_ID"

pushd "$ROOT/public-web" >/dev/null
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent "$WEB_BASE/?query=Recency%20Sort&sort=recent-desc&take=1" -o "$PAGE" && break
  kill -0 "$WEB_PID" >/dev/null 2>&1 || { cat "$WEB_LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$WEB_BASE/?query=Recency%20Sort&sort=recent-desc&take=1" -o "$PAGE" || { cat "$WEB_LOG" >&2; exit 1; }

python3 - "$PAGE" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    in_sort=False; found=False; selected=False
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if tag=='select' and values.get('name')=='sort':
            self.in_sort=True; self.found=True
        elif self.in_sort and tag=='option' and values.get('value')=='recent-desc' and 'selected' in values:
            self.selected=True
    def handle_endtag(self,tag):
        if tag=='select' and self.in_sort: self.in_sort=False
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
if not p.found: raise SystemExit('Discovery form missing sort control.')
if not p.selected: raise SystemExit('Recent sort selection not preserved in SSR.')
PY
grep -Fq "$NEWER_TITLE" "$PAGE" || { echo 'Recent SSR first page missing newest first publication.' >&2; exit 1; }
if grep -Fq "$OLDER_TITLE" "$PAGE"; then
  echo 'Recent SSR first page leaked older listing.' >&2; exit 1
fi
echo 'PUBLIC_RECENCY_SORT_SSR: PASS'

echo 'PUBLIC RECENCY SORT HTTP: PASSED'
