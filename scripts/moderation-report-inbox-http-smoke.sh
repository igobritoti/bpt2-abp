#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_MODERATION_API_PORT:-5102}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-moderation-report-inbox"
RESPONSE="$TMP/response.json"; LOG="$TMP/api.log"; SWAGGER="$TMP/swagger.json"
PAGE_HTML="$TMP/moderation.html"; LOGIN_HTML="$TMP/login.html"; HEADERS="$TMP/headers.txt"
ADMIN_COOKIES="$TMP/admin-cookies.txt"; BUYER_COOKIES="$TMP/buyer-cookies.txt"
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
expected={'/api/app/moderation-listing-report-query':'get','/api/app/listing-report/report/{listingId}':'post'}
for path,verb in expected.items():
    if path not in paths or verb not in paths[path]:
        raise SystemExit(f'Missing {verb.upper()} {path}; moderation/report routes={[(p,list(v)) for p,v in paths.items() if "report" in p or "moderation" in p]}')
print('MODERATION_REPORT_ROUTES: PASS')
PY

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
login_cookie(){
  local username="$1" password="$2" jar="$3" login_url effective verification status
  login_url="$BASE/Account/Login?returnUrl=%2Fmoderacao"
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

ADMIN_TOKEN="$(token admin '1q2w3E*')"
INBOX='/api/app/moderation-listing-report-query'
status="$(request GET "$INBOX")"; [[ "$status" == 401 ]] || { echo "Anonymous inbox expected 401 got $status" >&2; exit 1; }
echo 'MODERATION_REPORT_ANONYMOUS_BLOCKED: PASS'
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --write-out '%{http_code}' "$BASE/moderacao")"
[[ "$status" == 302 ]] || { echo "Anonymous moderation page expected 302 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fqi '/Account/Login' "$HEADERS" || { echo 'Anonymous moderation page did not redirect to Account login.' >&2; cat "$HEADERS" >&2; exit 1; }
echo 'MODERATION_PAGE_ANONYMOUS_BLOCKED: PASS'

create_user(){
  local username="$1" password="$2" email="${1}@example.invalid" body status
  body="$(python3 - "$username" "$email" "$password" <<'PY'
import json,sys
u,e,p=sys.argv[1:]; print(json.dumps({'userName':u,'name':'Buyer','surname':'Moderation','email':e,'password':p,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
  status="$(request POST '/api/identity/users' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { echo "User create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
}
BUYER="buyer-moderation-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; BUYER_PASSWORD='Bpt2-Mod-9!a'
create_user "$BUYER" "$BUYER_PASSWORD"
BUYER_TOKEN="$(token "$BUYER" "$BUYER_PASSWORD")"
status="$(request GET "$INBOX" "$BUYER_TOKEN")"; [[ "$status" == 403 ]] || { echo "Buyer inbox expected 403 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'MODERATION_REPORT_NON_ADMIN_BLOCKED: PASS'
login_cookie "$BUYER" "$BUYER_PASSWORD" "$BUYER_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$BUYER_COOKIES" "$BASE/moderacao")"
[[ "$status" == 403 ]] || { echo "Buyer moderation page expected 403 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
echo 'MODERATION_PAGE_NON_ADMIN_BLOCKED: PASS'

request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Moderation Fixture","whatsAppNumber":"5511999993333"}' >/dev/null
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Moderation queue fixture','price':145000,'description':'Fixture moderation inbox','manufactureYear':2024,'mileageKm':5000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request POST "/api/app/listing-report/report/$LISTING_ID" "$BUYER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || { cat "$RESPONSE"; exit 1; }

status="$(request GET "$INBOX" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Admin inbox expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); listing_id=sys.argv[2]
match=[x for x in items if x['listingId'].lower()==listing_id.lower()]
assert len(match)==1, items
x=match[0]
assert x['listingTitle']=='Moderation queue fixture', x
assert x['listingStatus']=='Published', x
assert x.get('reportId'), x
assert x.get('createdAtUtc'), x
for item in items:
    assert 'userId' not in item and 'buyerUserId' not in item, item
print('MODERATION_REPORT_ADMIN_VISIBLE: PASS')
print('MODERATION_REPORT_BUYER_PII_HIDDEN: PASS')
PY

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$ADMIN_COOKIES" "$BASE/moderacao")"
[[ "$status" == 200 ]] || { echo "Admin moderation page expected 200 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq 'Moderação de anúncios' "$PAGE_HTML" || { echo 'Moderation page title missing.' >&2; exit 1; }
grep -Fq 'Moderation queue fixture' "$PAGE_HTML" || { echo 'Moderation report Listing title missing from page.' >&2; exit 1; }
grep -Fq "$LISTING_ID" "$PAGE_HTML" || { echo 'Moderation report Listing id missing from page.' >&2; exit 1; }
if grep -Fq "$BUYER" "$PAGE_HTML"; then echo 'Buyer identity leaked into moderation page.' >&2; exit 1; fi
echo 'MODERATION_PAGE_ADMIN_VISIBLE: PASS'
echo 'MODERATION_PAGE_BUYER_PII_HIDDEN: PASS'

status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
status="$(request GET "$INBOX" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); listing_id=sys.argv[2]
match=[x for x in items if x['listingId'].lower()==listing_id.lower()]
assert len(match)==1, items
assert match[0]['listingStatus']=='Paused', match[0]
print('MODERATION_REPORT_HISTORY_PRESERVED: PASS')
PY
status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$ADMIN_COOKIES" "$BASE/moderacao")"
[[ "$status" == 200 ]] || { echo "Paused moderation page expected 200 got $status" >&2; exit 1; }
grep -Fq 'Paused' "$PAGE_HTML" || { echo 'Paused status missing from moderation page.' >&2; exit 1; }
grep -Fq "$LISTING_ID" "$PAGE_HTML" || { echo 'Historical report missing after pause.' >&2; exit 1; }
echo 'MODERATION_PAGE_HISTORY_PRESERVED: PASS'

echo 'MODERATION REPORT INBOX HTTP: PASSED'
