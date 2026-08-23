#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_REPORT_API_PORT:-5101}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-buyer-listing-report"
RESPONSE="$TMP/response.json"; LOG="$TMP/api.log"; SWAGGER="$TMP/swagger.json"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"
export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false
API_PID=""; cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" -o "$SWAGGER" && break; sleep 1; done
[[ -s "$SWAGGER" ]] || { cat "$LOG" >&2; exit 1; }
python3 - "$SWAGGER" <<'PY'
import json,sys
paths=json.load(open(sys.argv[1],encoding='utf-8'))['paths']
expected={'/api/app/listing-report/report':'post','/api/app/listing-report/is-reported/{listingId}':'get'}
for path,verb in expected.items():
    if path not in paths or verb not in paths[path]:
        raise SystemExit(f'Missing {verb.upper()} {path}; report routes={[(p,list(v)) for p,v in paths.items() if "report" in p]}')
print('BUYER_REPORT_ROUTES: PASS')
PY

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
ADMIN_TOKEN="$(token admin '1q2w3E*')"
request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Report Fixture","whatsAppNumber":"5511999992222"}' >/dev/null
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Listing report fixture','price':135000,'description':'Fixture moderation report','manufactureYear':2024,'mileageKm':8000,'color':'Preto','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
REPORT_PATH="/api/app/listing-report/report?listingId=$LISTING_ID"

status="$(request POST "$REPORT_PATH")"; [[ "$status" == 401 ]] || { echo "Anonymous report expected 401 got $status" >&2; exit 1; }
echo 'BUYER_REPORT_ANONYMOUS_BLOCKED: PASS'

create_user(){
  local username="$1" password="$2" email="${1}@example.invalid" body status
  body="$(python3 - "$username" "$email" "$password" <<'PY'
import json,sys
u,e,p=sys.argv[1:]; print(json.dumps({'userName':u,'name':'Buyer','surname':'Report','email':e,'password':p,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
  status="$(request POST '/api/identity/users' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "User create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
}
U1="buyer-report-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; P1='Bpt2-Report-9!a'
U2="buyer-report-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; P2='Bpt2-Report-9!b'
create_user "$U1" "$P1"; create_user "$U2" "$P2"
T1="$(token "$U1" "$P1")"; T2="$(token "$U2" "$P2")"

status="$(request POST "$REPORT_PATH" "$T1")"; [[ "$status" == 404 ]] || { echo "Draft report expected 404 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'BUYER_REPORT_DRAFT_BLOCKED: PASS'
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
for _ in 1 2; do status="$(request POST "$REPORT_PATH" "$T1")"; [[ "$status" == 200 || "$status" == 204 ]] || { cat "$RESPONSE"; exit 1; }; done
echo 'BUYER_REPORT_IDEMPOTENT: PASS'
status="$(request GET "/api/app/listing-report/is-reported/$LISTING_ID" "$T1")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == true ]] || exit 1
echo 'BUYER_REPORT_PERSISTED: PASS'
status="$(request GET "/api/app/listing-report/is-reported/$LISTING_ID" "$T2")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == false ]] || { cat "$RESPONSE"; exit 1; }
echo 'BUYER_REPORT_USER_ISOLATION: PASS'
status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request POST "$REPORT_PATH" "$T2")"; [[ "$status" == 404 ]] || { echo "Paused report expected 404 got $status" >&2; exit 1; }
status="$(request GET "/api/app/listing-report/is-reported/$LISTING_ID" "$T1")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == true ]] || exit 1
echo 'BUYER_REPORT_HISTORY_PRESERVED: PASS'
echo 'BUYER LISTING REPORT HTTP: PASSED'
