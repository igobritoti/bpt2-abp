#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_ADMIN_HUB_PORT:-5105}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-admin-operations-hub"
RESPONSE="$TMP/response.json"
HOST_LOG="$TMP/host.log"
PAGE_HTML="$TMP/page.html"
LOGIN_HTML="$TMP/login.html"
HEADERS="$TMP/headers.txt"
ADMIN_COOKIES="$TMP/admin-cookies.txt"
USER_COOKIES="$TMP/user-cookies.txt"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false

HOST_PID=""
cleanup() {
  [[ -z "$HOST_PID" ]] || kill "$HOST_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$BASE$path"
}

token() {
  curl --silent --show-error -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$1" \
    --data-urlencode "password=$2" \
    --data-urlencode 'scope=BomPraTi' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

login_cookie() {
  local username="$1" password="$2" jar="$3" effective verification status
  effective="$(curl --silent --show-error --location --max-redirs 5 --cookie-jar "$jar" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$BASE/Account/Login?returnUrl=%2Fadmin")"
  verification="$(python3 - "$LOGIN_HTML" <<'PY'
from html.parser import HTMLParser
import sys
class Parser(HTMLParser):
    value = None
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag.lower() == 'input' and values.get('name') == '__RequestVerificationToken':
            self.value = values.get('value')
p = Parser(); p.feed(open(sys.argv[1], encoding='utf-8').read())
if not p.value:
    raise SystemExit('Login antiforgery token not found')
print(p.value)
PY
)"
  status="$(curl --silent --show-error --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$jar" --cookie-jar "$jar" --write-out '%{http_code}' --request POST "$effective" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "__RequestVerificationToken=$verification" \
    --data-urlencode "LoginInput.UserNameOrEmailAddress=$username" \
    --data-urlencode "LoginInput.Password=$password" \
    --data-urlencode 'LoginInput.RememberMe=false' \
    --data-urlencode 'Action=Login')"
  [[ "$status" == 302 ]] || { echo "Account login for $username expected 302 got $status" >&2; cat "$RESPONSE" >&2; exit 1; }
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$HOST_LOG" 2>&1 & HOST_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break
  if ! kill -0 "$HOST_PID" >/dev/null 2>&1; then cat "$HOST_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$HOST_LOG" >&2; exit 1; }

status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 302 ]] || { echo "Anonymous admin hub expected 302 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fqi '/Account/Login' "$HEADERS" || { echo 'Anonymous admin hub did not redirect to Account login.' >&2; cat "$HEADERS" >&2; exit 1; }
echo 'ADMIN_HUB_ANONYMOUS_BLOCKED: PASS'

ADMIN_TOKEN="$(token admin '1q2w3E*')"
USER="admin-hub-nonadmin-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"
USER_PASSWORD='Bpt2-AdminHub-9!a'
USER_BODY="$(python3 - "$USER" "$USER_PASSWORD" <<'PY'
import json,sys
username,password=sys.argv[1:]
print(json.dumps({'userName':username,'name':'Admin','surname':'HubUser','email':f'{username}@example.invalid','password':password,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
status="$(request_json POST '/api/identity/users' "$ADMIN_TOKEN" "$USER_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Non-admin user create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

login_cookie "$USER" "$USER_PASSWORD" "$USER_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --cookie "$USER_COOKIES" --write-out '%{http_code}' "$BASE/admin")"
if [[ "$status" == 403 ]]; then
  :
elif [[ "$status" == 302 ]] && grep -Fqi 'AccessDenied' "$HEADERS"; then
  :
else
  echo "Non-admin admin hub expected 403 or AccessDenied redirect, got $status" >&2
  cat "$HEADERS" >&2
  cat "$PAGE_HTML" >&2
  exit 1
fi
echo 'ADMIN_HUB_NON_ADMIN_BLOCKED: PASS'

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --cookie "$ADMIN_COOKIES" --cookie-jar "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 200 ]] || { echo "Admin hub expected 200 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq 'Operações administrativas' "$PAGE_HTML" || { echo 'Admin hub title missing.' >&2; exit 1; }
grep -Fq 'Moderação de anúncios' "$PAGE_HTML" || { echo 'Moderation operation missing from admin hub.' >&2; exit 1; }
grep -Fq 'Ingestão de veículos' "$PAGE_HTML" || { echo 'Ingestion operation missing from admin hub.' >&2; exit 1; }
echo 'ADMIN_HUB_ADMIN_VISIBLE: PASS'

grep -Fq 'href="/moderacao"' "$PAGE_HTML" || { echo 'Moderation link missing from admin hub.' >&2; exit 1; }
grep -Fq 'href="/ingestao"' "$PAGE_HTML" || { echo 'Ingestion link missing from admin hub.' >&2; exit 1; }
echo 'ADMIN_HUB_LINKS: PASS'

status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$ADMIN_COOKIES" "$BASE/moderacao")"
[[ "$status" == 200 ]] || { echo "Moderation target expected 200 got $status" >&2; exit 1; }
status="$(curl --silent --show-error --output "$PAGE_HTML" --write-out '%{http_code}' --cookie "$ADMIN_COOKIES" "$BASE/ingestao")"
[[ "$status" == 200 ]] || { echo "Ingestion target expected 200 got $status" >&2; exit 1; }
echo 'ADMIN_HUB_TARGETS_REACHABLE: PASS'
echo 'ADMIN OPERATIONS HUB HTTP: PASSED'
