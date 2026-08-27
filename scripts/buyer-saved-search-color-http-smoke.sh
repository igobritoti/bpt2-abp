#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_SAVED_SEARCH_COLOR_API_PORT:-5108}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-saved-search-color"
RESPONSE="$TMP/response.json"
LOG="$TMP/api.log"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false

API_PID=""
cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

request(){
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$BASE$path"
}

token_for_admin(){
  curl --silent --show-error -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

[[ -f "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" ]] || {
  echo 'Host Release build missing; discovery setup must run first.' >&2; exit 1;
}

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break
  kill -0 "$API_PID" >/dev/null 2>&1 || { cat "$LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$LOG" >&2; exit 1; }

ADMIN_TOKEN="$(token_for_admin)"
request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Saved Search Color Fixture","whatsAppNumber":"5511999993333"}' >/dev/null

SILVER_BODY='{"query":"Saved Search Color Probe","color":" Prata "}'
status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" "$SILVER_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Silver saved-search create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
SILVER_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
assert x['query']=='Saved Search Color Probe',x
assert x['color']=='Prata',x
print(x['id'])
PY
)"

status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" '{"query":"saved search color probe","color":"prata"}')"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Silver semantic replay failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
SILVER_REPLAY_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
[[ "$SILVER_REPLAY_ID" == "$SILVER_ID" ]] || { echo 'Case-equivalent color created a duplicate SavedSearch.' >&2; exit 1; }
echo 'SAVED_SEARCH_COLOR_DEDUP: PASS'

status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" '{"query":"Saved Search Color Probe","color":"Preto"}')"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Black saved-search create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
BLACK_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
[[ "$BLACK_ID" != "$SILVER_ID" ]] || { echo 'Distinct colors collapsed into one SavedSearch.' >&2; exit 1; }
echo 'SAVED_SEARCH_COLOR_IDENTITY: PASS'

for id in "$SILVER_ID" "$BLACK_ID"; do
  status="$(request POST "/api/app/saved-search/$id/set-alert-enabled?enabled=true" "$ADMIN_TOKEN")"
  [[ "$status" == 200 ]] || { echo "Enable alert failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
done

LISTING_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId':sys.argv[1],
  'title':'Saved Search Color Probe Listing',
  'price':123000,
  'description':'Fixture de matching de busca salva por cor.',
  'manufactureYear':2024,
  'mileageKm':9000,
  'color':' PRATA ',
  'city':'São Paulo',
  'stateCode':'SP'
}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$LISTING_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Listing create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1],encoding='utf-8'))['id'])
PY
)"
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Publish failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 && "$(cat "$RESPONSE")" == 1 ]] || {
  echo "Color matching expected one SavedSearch match, got $status: $(cat "$RESPONSE")" >&2; exit 1;
}

status="$(request GET "/api/app/saved-search/$SILVER_ID/matches" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Silver matches failed $status" >&2; exit 1; }
python3 - "$RESPONSE" "$SILVER_ID" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1],encoding='utf-8'))
assert len(x)==1,x
assert x[0]['savedSearchId']==sys.argv[2] and x[0]['listingId']==sys.argv[3],x
PY

status="$(request GET "/api/app/saved-search/$BLACK_ID/matches" "$ADMIN_TOKEN")"
[[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || {
  echo "Black SavedSearch unexpectedly matched silver listing: $(cat "$RESPONSE")" >&2; exit 1;
}
echo 'SAVED_SEARCH_COLOR_MATCHING: PASS'

echo 'BUYER SAVED SEARCH COLOR HTTP: PASSED'
