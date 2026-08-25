#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_ADMIN_NAV_PORT:-5108}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-admin-global-navigation"
PAGE_HTML="$TMP/page.html"; LOGIN_HTML="$TMP/login.html"; RESPONSE="$TMP/response.json"; HEADERS="$TMP/headers.txt"; LOG="$TMP/host.log"
ADMIN_COOKIES="$TMP/admin-cookies.txt"; USER_COOKIES="$TMP/user-cookies.txt"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false
HOST_PID=""; cleanup(){ [[ -z "$HOST_PID" ]] || kill "$HOST_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

request_json(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent --show-error -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
login_cookie(){
  local username="$1" password="$2" jar="$3" return_url="$4" effective verification status
  effective="$(curl --silent --show-error --location --max-redirs 5 --cookie-jar "$jar" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$BASE/Account/Login?returnUrl=$return_url")"
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

assert_admin_anchor(){
  python3 - "$1" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.capture_depth = None
        self.parts = []
        self.found = False
    def handle_starttag(self, tag, attrs):
        self.depth += 1
        if tag.lower() == 'a' and dict(attrs).get('href') == '/admin':
            self.capture_depth = self.depth
            self.parts = []
    def handle_data(self, data):
        if self.capture_depth is not None:
            self.parts.append(data)
    def handle_endtag(self, tag):
        if tag.lower() == 'a' and self.capture_depth == self.depth:
            text = ' '.join(''.join(self.parts).split())
            if text == 'Operações':
                self.found = True
            self.capture_depth = None
            self.parts = []
        self.depth -= 1
p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read())
if not p.found:
    raise SystemExit('Admin global navigation anchor with text Operações missing.')
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & HOST_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break; if ! kill -0 "$HOST_PID" >/dev/null 2>&1; then cat "$LOG" >&2; exit 1; fi; sleep 1; done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$LOG" >&2; exit 1; }

ADMIN_TOKEN="$(token admin '1q2w3E*')"
USER="admin-nav-nonadmin-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"; USER_PASSWORD='Bpt2-AdminNav-9!a'
USER_BODY="$(python3 - "$USER" "$USER_PASSWORD" <<'PY'
import json,sys
u,p=sys.argv[1:]
print(json.dumps({'userName':u,'name':'Admin','surname':'NavigationUser','email':f'{u}@example.invalid','password':p,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
status="$(request_json POST '/api/identity/users' "$ADMIN_TOKEN" "$USER_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Non-admin user create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES" '%2Fadmin'
status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 200 ]] || { echo "Admin page expected 200 got $status" >&2; exit 1; }
assert_admin_anchor "$PAGE_HTML"
echo 'ADMIN_GLOBAL_NAV_VISIBLE: PASS'

login_cookie "$USER" "$USER_PASSWORD" "$USER_COOKIES" '%2FAccount%2FManage'
status="$(curl --silent --show-error --location --max-redirs 5 --output "$PAGE_HTML" --cookie "$USER_COOKIES" --cookie-jar "$USER_COOKIES" --write-out '%{http_code}' "$BASE/Account/Manage")"
[[ "$status" == 200 ]] || { echo "Authenticated account page expected 200 got $status" >&2; exit 1; }
if grep -Fq 'href="/admin"' "$PAGE_HTML"; then echo 'Non-admin received admin global navigation link.' >&2; exit 1; fi
echo 'ADMIN_GLOBAL_NAV_NON_ADMIN_HIDDEN: PASS'

echo 'ADMIN GLOBAL NAVIGATION HTTP: PASSED'
