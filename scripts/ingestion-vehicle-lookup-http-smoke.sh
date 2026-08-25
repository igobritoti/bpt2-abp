#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_INGESTION_LOOKUP_API_PORT:-5106}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-ingestion-vehicle-lookup"
RESPONSE="$TMP/response.json"; PAGE_HTML="$TMP/ingestion.html"; LOGIN_HTML="$TMP/login.html"; HEADERS="$TMP/headers.txt"; COOKIES="$TMP/admin-cookies.txt"; LOG="$TMP/api.log"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false
API_PID=""; cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$LOG" >&2; exit 1; }

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ curl --silent --show-error -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
login_admin(){
  local effective verification status
  effective="$(curl --silent --show-error --location --max-redirs 5 --cookie-jar "$COOKIES" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$BASE/Account/Login?returnUrl=%2Fingestao")"
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

ADMIN_TOKEN="$(token admin '1q2w3E*')"
SOURCE="lookup-ui-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:8])')"
BODY="$(python3 - "$SOURCE" <<'PY'
import json,sys
print(json.dumps({'source':sys.argv[1],'externalId':'lookup-vehicle-42','rawIdentity':'HTTP Lifecycle Version 2025','confidence':0.7,'provenance':'fixture://lookup/vehicle-42'}))
PY
)"
status="$(request POST '/api/app/ingestion-candidate' "$ADMIN_TOKEN" "$BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Candidate create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
RECORD_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"

login_admin
status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$BASE/ingestao?VehicleQuery=Lifecycle")"
[[ "$status" == 200 ]] || { echo "Vehicle lookup page expected 200 got $status" >&2; cat "$PAGE_HTML" >&2; exit 1; }
grep -Fq 'Vehicles canônicos encontrados' "$PAGE_HTML" || { echo 'Vehicle lookup result heading missing.' >&2; exit 1; }
grep -Fq "$BPT_FIXTURE_VEHICLE_ID" "$PAGE_HTML" || { echo 'Canonical fixture VehicleId missing from lookup.' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Model' "$PAGE_HTML" || { echo 'Canonical model missing from lookup.' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Version' "$PAGE_HTML" || { echo 'Canonical version missing from lookup.' >&2; exit 1; }
grep -Fq 'id="vehicle-options"' "$PAGE_HTML" || { echo 'Vehicle datalist missing.' >&2; exit 1; }
grep -Fq "data-vehicle-id=\"$BPT_FIXTURE_VEHICLE_ID\"" "$PAGE_HTML" || { echo 'Canonical Vehicle result marker missing.' >&2; exit 1; }
grep -Fq "$RECORD_ID" "$PAGE_HTML" || { echo 'Pending candidate disappeared during Vehicle lookup.' >&2; exit 1; }
echo 'INGESTION_VEHICLE_LOOKUP_TEXT: PASS'

status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$BASE/ingestao?VehicleQuery=HTTP-G1")"
[[ "$status" == 200 ]] || exit 1
grep -Fq "$BPT_FIXTURE_VEHICLE_ID" "$PAGE_HTML" || { echo 'Generation lookup did not find canonical fixture.' >&2; exit 1; }
grep -Fq 'HTTP-G1' "$PAGE_HTML" || { echo 'Canonical generation missing from lookup.' >&2; exit 1; }
echo 'INGESTION_VEHICLE_LOOKUP_GENERATION: PASS'

status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$BASE/ingestao?VehicleQuery=NoSuchCanonicalVehicleZzz")"
[[ "$status" == 200 ]] || exit 1
grep -Fq 'Nenhum Vehicle canônico encontrado.' "$PAGE_HTML" || { echo 'Vehicle lookup empty state missing.' >&2; exit 1; }
grep -Fq "$RECORD_ID" "$PAGE_HTML" || { echo 'Pending candidate disappeared on empty lookup.' >&2; exit 1; }
if grep -Fq "$BPT_FIXTURE_VEHICLE_ID" "$PAGE_HTML"; then echo 'Unexpected canonical Vehicle leaked into empty lookup.' >&2; exit 1; fi
echo 'INGESTION_VEHICLE_LOOKUP_EMPTY: PASS'

echo 'INGESTION VEHICLE LOOKUP HTTP: PASSED'
