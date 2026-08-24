#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_INGESTION_API_PORT:-5104}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-ingestion-candidate"
RESPONSE="$TMP/response.json"; LOG="$TMP/api.log"; SWAGGER="$TMP/swagger.json"
PAGE_HTML="$TMP/ingestion.html"; LOGIN_HTML="$TMP/login.html"; HEADERS="$TMP/headers.txt"
ADMIN_COOKIES="$TMP/admin-cookies.txt"; USER_COOKIES="$TMP/user-cookies.txt"
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
login_cookie(){
  local username="$1" password="$2" jar="$3" login_url effective verification status
  login_url="$BASE/Account/Login?returnUrl=%2Fingestao"
  effective="$(curl --silent --show-error --location --max-redirs 5 --cookie-jar "$jar" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$login_url")"
  verification="$(python3 - "$LOGIN_HTML" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    value=None
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if tag.lower()=='input' and values.get('name')=='__RequestVerificationToken': self.value=values.get('value')
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
if not p.value: raise SystemExit('Login antiforgery token not found')
print(p.value)
PY
)"
  status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$jar" --cookie-jar "$jar" --write-out '%{http_code}' --request POST "$effective" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "__RequestVerificationToken=$verification" --data-urlencode "LoginInput.UserNameOrEmailAddress=$username" --data-urlencode "LoginInput.Password=$password" --data-urlencode 'LoginInput.RememberMe=false' --data-urlencode 'Action=Login')"
  [[ "$status" == 302 ]] || { echo "Account login for $username expected 302 got $status" >&2; cat "$RESPONSE" >&2; exit 1; }
}
page_token(){
  local record_id="$1"
  python3 - "$PAGE_HTML" "$record_id" <<'PY'
from html.parser import HTMLParser
import sys
rid=sys.argv[2].lower()
class P(HTMLParser):
    def __init__(self):
        super().__init__(); self.form=None; self.forms=[]
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if tag.lower()=='form': self.form={}
        elif tag.lower()=='input' and self.form is not None:
            name=values.get('name'); value=values.get('value')
            if name: self.form[name]=value
    def handle_endtag(self,tag):
        if tag.lower()=='form' and self.form is not None:
            self.forms.append(self.form); self.form=None
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read())
for form in p.forms:
    if (form.get('RecordId') or '').lower()==rid:
        token=form.get('__RequestVerificationToken')
        if not token: raise SystemExit('Ingestion form antiforgery token not found')
        print(token); break
else: raise SystemExit('Ingestion form for record not found')
PY
}

ADMIN_TOKEN="$(token admin '1q2w3E*')"
BASE_PATH='/api/app/ingestion-candidate'
PENDING="$BASE_PATH/pending"

status="$(request GET "$PENDING")"; [[ "$status" == 401 ]] || { echo "Anonymous pending expected 401 got $status" >&2; exit 1; }
echo 'INGESTION_ANONYMOUS_BLOCKED: PASS'
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --write-out '%{http_code}' "$BASE/ingestao")"
[[ "$status" == 302 ]] || { echo "Anonymous ingestion page expected 302 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fqi '/Account/Login' "$HEADERS" || { echo 'Anonymous ingestion page did not redirect to Account login.' >&2; cat "$HEADERS" >&2; exit 1; }
echo 'INGESTION_PAGE_ANONYMOUS_BLOCKED: PASS'

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
login_cookie "$USER" "$USER_PASSWORD" "$USER_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --write-out '%{http_code}' --cookie "$USER_COOKIES" "$BASE/ingestao")"
if [[ "$status" == 403 ]]; then
  :
elif [[ "$status" == 302 ]] && grep -Fqi 'AccessDenied' "$HEADERS"; then
  :
else
  echo "Non-admin ingestion page expected 403 or AccessDenied redirect, got $status" >&2
  cat "$HEADERS" >&2
  cat "$PAGE_HTML" >&2
  exit 1
fi
echo 'INGESTION_PAGE_NON_ADMIN_BLOCKED: PASS'

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

UI_SOURCE="ui-fixture-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"
UI_BODY="$(python3 - "$UI_SOURCE" <<'PY'
import json,sys
print(json.dumps({'source':sys.argv[1],'externalId':'vehicle-ui-42','rawIdentity':'Marca UI Modelo 1.5 2025','confidence':0.625,'provenance':'fixture://ui/vehicle-ui-42'}))
PY
)"
status="$(request POST "$BASE_PATH" "$ADMIN_TOKEN" "$UI_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "UI candidate create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
UI_RECORD_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/ingestao")"
[[ "$status" == 200 ]] || { echo "Admin ingestion page expected 200 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq 'Ingestão de veículos' "$PAGE_HTML" || { echo 'Ingestion page title missing.' >&2; exit 1; }
grep -Fq "$UI_RECORD_ID" "$PAGE_HTML" || { echo 'Pending record id missing from ingestion page.' >&2; exit 1; }
grep -Fq "$UI_SOURCE" "$PAGE_HTML" || { echo 'Source missing from ingestion page.' >&2; exit 1; }
grep -Fq 'vehicle-ui-42' "$PAGE_HTML" || { echo 'ExternalId missing from ingestion page.' >&2; exit 1; }
grep -Fq 'Marca UI Modelo 1.5 2025' "$PAGE_HTML" || { echo 'RawIdentity missing from ingestion page.' >&2; exit 1; }
grep -Fq 'data-confidence="0.625"' "$PAGE_HTML" || { echo 'Confidence missing from ingestion page.' >&2; exit 1; }
grep -Fq 'fixture://ui/vehicle-ui-42' "$PAGE_HTML" || { echo 'Provenance missing from ingestion page.' >&2; exit 1; }
echo 'INGESTION_PAGE_ADMIN_VISIBLE: PASS'

UI_BAD_VEHICLE="$(python3 -c 'import uuid; print(uuid.uuid4())')"
VERIFICATION="$(page_token "$UI_RECORD_ID")"
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' --request POST "$BASE/ingestao?handler=Reconcile" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "__RequestVerificationToken=$VERIFICATION" --data-urlencode "RecordId=$UI_RECORD_ID" --data-urlencode "VehicleId=$UI_BAD_VEHICLE")"
[[ "$status" == 200 ]] || { echo "Unknown Vehicle UI reconcile expected 200 validation page got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq 'Vehicle canônico não encontrado' "$PAGE_HTML" || { echo 'Unknown Vehicle validation message missing.' >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq "$UI_RECORD_ID" "$PAGE_HTML" || { echo 'Candidate disappeared after rejected UI reconcile.' >&2; exit 1; }
status="$(request GET "$PENDING" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$UI_RECORD_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); rid=sys.argv[2].lower()
assert any(x['id'].lower()==rid and x.get('reconciledVehicleId') is None for x in items),items
print('INGESTION_PAGE_UNKNOWN_VEHICLE_REJECTED: PASS')
PY

VERIFICATION="$(page_token "$UI_RECORD_ID")"
status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' --request POST "$BASE/ingestao?handler=Reconcile" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "__RequestVerificationToken=$VERIFICATION" --data-urlencode "RecordId=$UI_RECORD_ID" --data-urlencode "VehicleId=$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 302 ]] || { echo "Canonical Vehicle UI reconcile expected 302 got $status" >&2; cat "$RESPONSE" >&2; exit 1; }
status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/ingestao")"
[[ "$status" == 200 ]] || { echo "Ingestion page after reconcile expected 200 got $status" >&2; exit 1; }
if grep -Fq "$UI_RECORD_ID" "$PAGE_HTML"; then echo 'Reconciled candidate still rendered on ingestion page.' >&2; exit 1; fi
echo 'INGESTION_PAGE_CANONICAL_VEHICLE_RECONCILED: PASS'
status="$(request GET "$PENDING" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$UI_RECORD_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); rid=sys.argv[2].lower()
assert all(x['id'].lower()!=rid for x in items),items
print('INGESTION_PAGE_RECONCILED_REMOVED: PASS')
PY

echo 'INGESTION ADMIN SURFACE HTTP: PASSED'
