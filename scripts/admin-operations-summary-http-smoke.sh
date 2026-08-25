#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_ADMIN_SUMMARY_PORT:-5107}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-admin-operations-summary"
RESPONSE="$TMP/response.json"; PAGE_HTML="$TMP/page.html"; LOGIN_HTML="$TMP/login.html"; HEADERS="$TMP/headers.txt"; COOKIES="$TMP/admin-cookies.txt"; LOG="$TMP/host.log"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false
HOST_PID=""; cleanup(){ [[ -z "$HOST_PID" ]] || kill "$HOST_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & HOST_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$LOG" >&2; exit 1; }

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent --show-error -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
login_admin(){
  local effective verification status
  effective="$(curl --silent --show-error --location --max-redirs 5 --cookie-jar "$COOKIES" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$BASE/Account/Login?returnUrl=%2Fadmin")"
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
  status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' --request POST "$effective" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "__RequestVerificationToken=$verification" --data-urlencode 'LoginInput.UserNameOrEmailAddress=admin' --data-urlencode 'LoginInput.Password=1q2w3E*' --data-urlencode 'LoginInput.RememberMe=false' --data-urlencode 'Action=Login')"
  [[ "$status" == 302 ]] || { echo "Admin login expected 302 got $status" >&2; cat "$RESPONSE" >&2; exit 1; }
}
metric(){
  python3 - "$PAGE_HTML" "$1" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    value=None
    def __init__(self,name): super().__init__(); self.name=name
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if values.get('data-admin-metric')==self.name: self.value=values.get('data-admin-count')
p=P(sys.argv[2]); p.feed(open(sys.argv[1],encoding='utf-8').read())
if p.value is None: raise SystemExit(f'metric not found: {sys.argv[2]}')
print(int(p.value))
PY
}

ADMIN_TOKEN="$(token admin '1q2w3E*')"
login_admin
status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 200 ]] || { echo "Admin summary expected 200 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
CANONICAL_COUNT="$(metric canonical-vehicles)"
REPORT_COUNT="$(metric moderation-reports)"
PENDING_BEFORE="$(metric pending-ingestion)"
(( CANONICAL_COUNT >= 1 )) || { echo "Expected at least one canonical Vehicle, got $CANONICAL_COUNT" >&2; exit 1; }
(( REPORT_COUNT >= 0 )) || exit 1
(( PENDING_BEFORE >= 0 )) || exit 1
grep -Fq 'Vehicles canônicos:' "$PAGE_HTML" || { echo 'Canonical Vehicle summary label missing.' >&2; exit 1; }
grep -Fq 'Reports recebidos:' "$PAGE_HTML" || { echo 'Moderation report summary label missing.' >&2; exit 1; }
grep -Fq 'Candidates pendentes:' "$PAGE_HTML" || { echo 'Ingestion pending summary label missing.' >&2; exit 1; }
echo 'ADMIN_SUMMARY_RUNTIME_COUNTS: PASS'

SOURCE="admin-summary-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"
BODY="$(python3 - "$SOURCE" <<'PY'
import json,sys
print(json.dumps({'source':sys.argv[1],'externalId':'pending-count-1','rawIdentity':'Admin summary pending candidate','confidence':0.5,'provenance':'fixture://admin-summary/pending-count-1'}))
PY
)"
status="$(request POST '/api/app/ingestion-candidate' "$ADMIN_TOKEN" "$BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Candidate create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 200 ]] || exit 1
PENDING_AFTER="$(metric pending-ingestion)"
[[ "$PENDING_AFTER" -eq $((PENDING_BEFORE + 1)) ]] || { echo "Pending count expected $((PENDING_BEFORE + 1)) got $PENDING_AFTER" >&2; exit 1; }
echo 'ADMIN_SUMMARY_PENDING_DELTA: PASS'

echo 'ADMIN OPERATIONS SUMMARY HTTP: PASSED'
