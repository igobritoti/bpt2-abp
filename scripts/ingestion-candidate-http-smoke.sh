#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_INGESTION_API_PORT:-5104}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-ingestion-candidate"
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
expected={
    '/api/app/ingestion-candidate':'post',
    '/api/app/ingestion-candidate/pending':'get',
    '/api/app/ingestion-candidate/reconcile':'post',
}
for path,verb in expected.items():
    if path not in paths or verb not in paths[path]:
        raise SystemExit(f'Missing {verb.upper()} {path}; ingestion routes={[(p,list(v)) for p,v in paths.items() if "ingestion" in p]}')
print('INGESTION_CANDIDATE_ROUTES: PASS')
PY

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
ADMIN_TOKEN="$(token admin '1q2w3E*')"
BASE_PATH='/api/app/ingestion-candidate'
PENDING="$BASE_PATH/pending"

status="$(request GET "$PENDING")"; [[ "$status" == 401 ]] || { echo "Anonymous pending expected 401 got $status" >&2; exit 1; }
echo 'INGESTION_ANONYMOUS_BLOCKED: PASS'

create_user(){
  local username="$1" password="$2" email="${1}@example.invalid" body status
  body="$(python3 - "$username" "$email" "$password" <<'PY'
import json,sys
u,e,p=sys.argv[1:]; print(json.dumps({'userName':u,'name':'Ingestion','surname':'Operator','email':e,'password':p,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
  status="$(request POST '/api/identity/users' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "User create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
}
USER="ingestion-nonadmin-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; USER_PASSWORD='Bpt2-Ingest-9!a'
create_user "$USER" "$USER_PASSWORD"
USER_TOKEN="$(token "$USER" "$USER_PASSWORD")"
status="$(request GET "$PENDING" "$USER_TOKEN")"; [[ "$status" == 403 ]] || { echo "Non-admin pending expected 403 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'INGESTION_NON_ADMIN_BLOCKED: PASS'

SOURCE="fixture-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"
BODY="$(python3 - "$SOURCE" <<'PY'
import json,sys
print(json.dumps({'source':sys.argv[1],'externalId':'vehicle-42','rawIdentity':'Marca Modelo 2.0 2024','confidence':0.875,'provenance':'fixture://source/vehicle-42'}))
PY
)"
status="$(request POST "$BASE_PATH" "$ADMIN_TOKEN" "$BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Admin create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
RECORD_ID="$(python3 - "$RESPONSE" "$SOURCE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); source=sys.argv[2]
assert x['source']==source,x
assert x['externalId']=='vehicle-42',x
assert x['rawIdentity']=='Marca Modelo 2.0 2024',x
assert abs(float(x['confidence'])-0.875)<1e-9,x
assert x['provenance']=='fixture://source/vehicle-42',x
assert x.get('reconciledVehicleId') is None,x
print(x['id'])
PY
)"
echo 'INGESTION_ADMIN_CREATE: PASS'

status="$(request POST "$BASE_PATH" "$ADMIN_TOKEN" "$BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || exit 1
DUPLICATE_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
[[ "$DUPLICATE_ID" == "$RECORD_ID" ]] || { echo "Duplicate identity created a second record" >&2; exit 1; }
echo 'INGESTION_EXTERNAL_ID_DEDUPED: PASS'

status="$(request GET "$PENDING" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$RECORD_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); rid=sys.argv[2].lower()
match=[x for x in items if x['id'].lower()==rid]
assert len(match)==1,items
assert match[0].get('reconciledVehicleId') is None,match[0]
print('INGESTION_PENDING_VISIBLE: PASS')
PY

BAD_VEHICLE="$(python3 -c 'import uuid; print(uuid.uuid4())')"
status="$(request POST "$BASE_PATH/reconcile?recordId=$RECORD_ID&vehicleId=$BAD_VEHICLE" "$ADMIN_TOKEN")"; [[ "$status" == 404 ]] || { echo "Unknown Vehicle expected 404 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request GET "$PENDING" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$RECORD_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); rid=sys.argv[2].lower()
assert any(x['id'].lower()==rid and x.get('reconciledVehicleId') is None for x in items),items
print('INGESTION_UNKNOWN_VEHICLE_REJECTED: PASS')
PY

status="$(request POST "$BASE_PATH/reconcile?recordId=$RECORD_ID&vehicleId=$BPT_FIXTURE_VEHICLE_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Canonical Vehicle reconcile failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); expected=sys.argv[2].lower()
assert x['reconciledVehicleId'].lower()==expected,x
print('INGESTION_CANONICAL_VEHICLE_RECONCILED: PASS')
PY
status="$(request GET "$PENDING" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$RECORD_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); rid=sys.argv[2].lower()
assert all(x['id'].lower()!=rid for x in items),items
print('INGESTION_RECONCILED_REMOVED_FROM_PENDING: PASS')
PY

echo 'INGESTION CANDIDATE HTTP: PASSED'
