#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5106}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-buyer-saved-search"
LOG="$TMP/api.log"; RESPONSE="$TMP/response.json"; SWAGGER="$TMP/swagger.json"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"
export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false
API_PID=""; cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" -o "$SWAGGER" && break; sleep 1; done
[[ -s "$SWAGGER" ]] || { cat "$LOG" >&2; exit 1; }
python3 - "$SWAGGER" <<'PY'
import json,sys
paths=json.load(open(sys.argv[1]))['paths']
expected={
 '/api/app/saved-search':'post',
 '/api/app/saved-search/mine':'get',
 '/api/app/saved-search/{id}':'delete',
 '/api/app/saved-search/{id}/set-alert-enabled':'post',
 '/api/app/saved-search/{id}/matches':'get',
 '/api/app/saved-search-alert-detection/evaluate/{listingId}':'post',
}
for path,verb in expected.items():
    if path not in paths or verb not in paths[path]:
        actual={p:list(v) for p,v in paths.items() if 'saved-search' in p}
        raise SystemExit(f'Missing Saved Search route {verb.upper()} {path}; actual={actual}')
print('BUYER_SAVED_SEARCH_ROUTES: PASS')
PY

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token_for(){
  local username="$1" password="$2"
  local file="$TMP/token-$username.json" status
  status="$(curl --silent --show-error --output "$file" --write-out '%{http_code}' -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$username" --data-urlencode "password=$password" --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == 200 ]] || { echo "Token failed $status: $(cat "$file")" >&2; exit 1; }
  python3 - "$file" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['access_token'])
PY
}
register_user(){
  local username="$1" password="$2"
  local email="$username@example.invalid" body status
  body="$(python3 - "$username" "$email" "$password" <<'PY'
import json,sys; print(json.dumps({'userName':sys.argv[1],'emailAddress':sys.argv[2],'password':sys.argv[3],'appName':'MVC'}))
PY
)"
  status="$(request POST '/api/account/register' '' "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "Register failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
}

ADMIN_TOKEN="$(token_for admin '1q2w3E*')"
BODY_ONE='{"brand":" Honda ","model":" Civic ","city":" São Paulo ","stateCode":"sp","minModelYear":2020,"maxModelYear":2025,"minPrice":80000,"maxPrice":160000,"minMileageKm":0,"maxMileageKm":80000,"query":" Turbo "}'
status="$(request POST '/api/app/saved-search' '' "$BODY_ONE")"; [[ "$status" == 401 ]] || { echo "Anonymous save expected 401 got $status" >&2; exit 1; }
echo 'BUYER_SAVED_SEARCH_ANONYMOUS_BLOCKED: PASS'

status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" "$BODY_ONE")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
FIRST_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['brand']=='Honda' and x['model']=='Civic' and x['city']=='São Paulo' and x['stateCode']=='SP' and x['query']=='Turbo',x
assert x['alertEnabled'] is False,x
assert 'sort' not in x and 'skip' not in x and 'take' not in x,x
print(x['id'])
PY
)"
BODY_SAME='{"brand":"honda","model":"civic","city":"são paulo","stateCode":"SP","minModelYear":2020,"maxModelYear":2025,"minPrice":80000.00,"maxPrice":160000.0,"minMileageKm":0,"maxMileageKm":80000,"query":"turbo","sort":"price-desc","skip":40,"take":1}'
status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" "$BODY_SAME")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Semantic replay failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
SECOND_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert 'sort' not in x and 'skip' not in x and 'take' not in x,x
print(x['id'])
PY
)"
[[ "$SECOND_ID" == "$FIRST_ID" ]] || { echo "Semantic duplicate created a new SavedSearch" >&2; exit 1; }
status="$(request GET '/api/app/saved-search/mine' "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$FIRST_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert len(x)==1 and x[0]['id']==sys.argv[2],x
PY
echo 'BUYER_SAVED_SEARCH_SEMANTIC_DEDUP: PASS'

OTHER_USER="buyer-saved-$(python3 - <<'PY'
import uuid; print(uuid.uuid4().hex[:10])
PY
)"; OTHER_PASSWORD='Bpt2-SavedSearch-9!x'
register_user "$OTHER_USER" "$OTHER_PASSWORD"
OTHER_TOKEN="$(token_for "$OTHER_USER" "$OTHER_PASSWORD")"
status="$(request GET '/api/app/saved-search/mine' "$OTHER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || { echo "Saved search leaked to another Buyer" >&2; cat "$RESPONSE"; exit 1; }
status="$(request DELETE "/api/app/saved-search/$FIRST_ID" "$OTHER_TOKEN")"; [[ "$status" == 404 ]] || { echo "Foreign delete expected 404 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request GET '/api/app/saved-search/mine' "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" <<'PY'
import json,sys; assert len(json.load(open(sys.argv[1])))==1
PY
echo 'BUYER_SAVED_SEARCH_OWNERSHIP: PASS'

# Alert contract: opt-in is explicit and detection is separate from delivery/provider.
MATCH_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'city':'São Paulo','stateCode':'SP','maxPrice':150000,'maxMileageKm':20000}))
PY
)"
status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" "$MATCH_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Alert search create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
ALERT_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['alertEnabled'] is False,x; print(x['id'])
PY
)"
INCOMPATIBLE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'city':'São Paulo','stateCode':'SP','maxPrice':100}))
PY
)"
status="$(request POST '/api/app/saved-search' "$ADMIN_TOKEN" "$INCOMPATIBLE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || exit 1
INCOMPATIBLE_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"

request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Saved Search Alert Fixture","whatsAppNumber":"5511999992222"}' >/dev/null
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Saved Search Alert Fixture Turbo','price':123000,'description':'Fixture de alerta de nova oferta','manufactureYear':2024,'mileageKm':9000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Alert Listing create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"

# Disabled search and Draft listing both fail closed.
status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == 0 ]] || { echo "Draft detection expected 0 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request POST "/api/app/saved-search/$ALERT_ID/set-alert-enabled?enabled=true" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Enable alert failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys; assert json.load(open(sys.argv[1]))['alertEnabled'] is True
PY
status="$(request POST "/api/app/saved-search/$INCOMPATIBLE_ID/set-alert-enabled?enabled=true" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == 0 ]] || { echo "Enabled Draft detection expected 0 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'BUYER_SAVED_SEARCH_ALERT_DRAFT_BLOCKED: PASS'

status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Publish failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == 1 ]] || { echo "Published detection expected one new match got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == 0 ]] || { echo "Replay detection expected zero new matches got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request GET "/api/app/saved-search/$ALERT_ID/matches" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$ALERT_ID" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert len(x)==1,x; assert x[0]['savedSearchId']==sys.argv[2] and x[0]['listingId']==sys.argv[3],x
PY
status="$(request GET "/api/app/saved-search/$INCOMPATIBLE_ID/matches" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || { echo "Incompatible search unexpectedly matched" >&2; cat "$RESPONSE"; exit 1; }
echo 'BUYER_SAVED_SEARCH_ALERT_PUBLIC_MATCH_AND_FILTERS: PASS'

status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request POST "/api/app/saved-search-alert-detection/evaluate/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == 0 ]] || { echo "Republish must not duplicate match" >&2; cat "$RESPONSE"; exit 1; }
echo 'BUYER_SAVED_SEARCH_ALERT_REPUBLISH_IDEMPOTENT: PASS'

status="$(request GET "/api/app/saved-search/$ALERT_ID/matches" "$OTHER_TOKEN")"; [[ "$status" == 404 ]] || { echo "Foreign matches read expected 404 got $status" >&2; exit 1; }
status="$(request POST "/api/app/saved-search/$ALERT_ID/set-alert-enabled?enabled=false" "$OTHER_TOKEN")"; [[ "$status" == 404 ]] || { echo "Foreign alert control expected 404 got $status" >&2; exit 1; }
status="$(request POST "/api/app/saved-search/$ALERT_ID/set-alert-enabled?enabled=false" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" <<'PY'
import json,sys; assert json.load(open(sys.argv[1]))['alertEnabled'] is False
PY
echo 'BUYER_SAVED_SEARCH_ALERT_OWNERSHIP_AND_OPTOUT: PASS'

for id in "$FIRST_ID" "$ALERT_ID" "$INCOMPATIBLE_ID"; do
  status="$(request DELETE "/api/app/saved-search/$id" "$ADMIN_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || { cat "$RESPONSE"; exit 1; }
done
status="$(request GET '/api/app/saved-search/mine' "$ADMIN_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || { cat "$RESPONSE"; exit 1; }
echo 'BUYER_SAVED_SEARCH_DELETE: PASS'
