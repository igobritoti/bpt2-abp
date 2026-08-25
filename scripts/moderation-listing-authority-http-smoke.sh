#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_MODERATION_AUTHORITY_API_PORT:-5104}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-moderation-listing-authority"
RESPONSE="$TMP/response.json"; LOG="$TMP/api.log"; SWAGGER="$TMP/swagger.json"
PAGE_HTML="$TMP/moderation.html"; LOGIN_HTML="$TMP/login.html"; HEADERS="$TMP/headers.txt"
ADMIN_COOKIES="$TMP/admin-cookies.txt"
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
 '/api/app/moderation-listing-report-query':'get',
 '/api/app/moderation-listing-command/withdraw/{listingId}':'post',
 '/api/app/moderation-listing-command/restore/{listingId}':'post',
 '/api/app/listing-report/report/{listingId}':'post',
 '/api/app/public-listing/{id}':'get',
}
for path,verb in expected.items():
    if path not in paths or verb not in paths[path]:
        raise SystemExit(f'Missing {verb.upper()} {path}; matching routes={[(p,list(v)) for p,v in paths.items() if "listing" in p or "moderation" in p]}')
print('MODERATION_AUTHORITY_ROUTES: PASS')
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
BUYER="buyer-authority-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; BUYER_PASSWORD='Bpt2-Mod-9!a'
create_user "$BUYER" "$BUYER_PASSWORD"
BUYER_TOKEN="$(token "$BUYER" "$BUYER_PASSWORD")"

WITHDRAW='/api/app/moderation-listing-command/withdraw'
RESTORE='/api/app/moderation-listing-command/restore'
status="$(request POST "$WITHDRAW/00000000-0000-0000-0000-000000000001")"; [[ "$status" == 401 ]] || { echo "Anonymous moderation command expected 401 got $status" >&2; exit 1; }
status="$(request POST "$WITHDRAW/00000000-0000-0000-0000-000000000001" "$BUYER_TOKEN")"; [[ "$status" == 403 ]] || { echo "Non-admin moderation command expected 403 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'MODERATION_AUTHORITY_ACCESS_BOUNDARY: PASS'

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Moderation authority fixture','price':145000,'description':'Fixture moderation authority','manufactureYear':2024,'mileageKm':5000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Listing create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Publish failed $status" >&2; exit 1; }
status="$(request POST "/api/app/listing-report/report/$LISTING_ID" "$BUYER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || { echo "Report failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request GET "/api/app/public-listing/$LISTING_ID")"; [[ "$status" == 200 ]] || { echo "Published listing expected public 200 got $status" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['id'].lower()==sys.argv[2].lower(), x
print('MODERATION_AUTHORITY_PRECONDITION_PUBLIC: PASS')
PY

status="$(request POST "$WITHDRAW/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Admin withdraw expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['status']=='Moderated', x
print('MODERATION_AUTHORITY_WITHDRAW: PASS')
PY

status="$(request GET "/api/app/public-listing/$LISTING_ID")"
if [[ "$status" == 200 ]]; then
  python3 - "$RESPONSE" <<'PY'
import json,sys
raw=open(sys.argv[1],encoding='utf-8').read().strip()
if raw not in ('','null'):
    raise SystemExit(f'Moderated listing leaked publicly: {raw}')
PY
elif [[ "$status" != 204 && "$status" != 404 ]]; then
  echo "Moderated public detail expected null/204/404 got $status: $(cat "$RESPONSE")" >&2; exit 1
fi
echo 'MODERATION_AUTHORITY_PUBLIC_HIDDEN: PASS'

status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" != 200 && "$status" != 201 && "$status" != 204 ]] || { echo 'Seller publish unexpectedly reversed moderation.' >&2; exit 1; }
grep -Fq 'Marketplace:ListingModerated' "$RESPONSE" || { echo "Seller publish blocked without expected moderation code: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'MODERATION_AUTHORITY_SELLER_PUBLISH_BLOCKED: PASS'

INBOX='/api/app/moderation-listing-report-query'
status="$(request GET "$INBOX" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Admin inbox expected 200 got $status" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); lid=sys.argv[2].lower(); match=[x for x in items if x['listingId'].lower()==lid]
assert len(match)==1, items
assert match[0]['listingStatus']=='Moderated', match[0]
for item in items: assert 'userId' not in item and 'buyerUserId' not in item, item
print('MODERATION_AUTHORITY_INBOX_STATE_AND_PII: PASS')
PY

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$ADMIN_COOKIES" "$BASE/moderacao")"
[[ "$status" == 200 ]] || { echo "Admin moderation page expected 200 got $status" >&2; exit 1; }
grep -Fq 'Moderation authority fixture' "$PAGE_HTML" || { echo 'Moderation listing title missing.' >&2; exit 1; }
grep -Fq 'Moderated' "$PAGE_HTML" || { echo 'Moderated status missing.' >&2; exit 1; }
grep -Fq 'Restaurar' "$PAGE_HTML" || { echo 'Restore action missing.' >&2; exit 1; }
if grep -Fq "$BUYER" "$PAGE_HTML"; then echo 'Buyer identity leaked into moderation page.' >&2; exit 1; fi
echo 'MODERATION_AUTHORITY_PAGE: PASS'

status="$(request POST "$RESTORE/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { echo "Admin restore expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['status']=='Published', x
print('MODERATION_AUTHORITY_RESTORE: PASS')
PY
status="$(request GET "/api/app/public-listing/$LISTING_ID")"; [[ "$status" == 200 ]] || { echo "Restored listing expected public 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['id'].lower()==sys.argv[2].lower(), x
print('MODERATION_AUTHORITY_PUBLIC_RESTORED: PASS')
PY

echo 'MODERATION LISTING AUTHORITY HTTP: PASSED'
