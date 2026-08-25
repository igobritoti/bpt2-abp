#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_CANONICAL_CATALOG_PORT:-5106}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-admin-canonical-catalog"
RESPONSE="$TMP/response.json"
SWAGGER="$TMP/swagger.json"
HOST_LOG="$TMP/host.log"
PAGE_HTML="$TMP/page.html"
LOGIN_HTML="$TMP/login.html"
HEADERS="$TMP/headers.txt"
ADMIN_COOKIES="$TMP/admin-cookies.txt"

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
  local username="$1" password="$2"
  curl --silent --show-error -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
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
  if curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$HOST_PID" >/dev/null 2>&1; then cat "$HOST_LOG" >&2; exit 1; fi
  sleep 1
done
[[ -s "$SWAGGER" ]] || { cat "$HOST_LOG" >&2; echo 'Swagger did not become available.' >&2; exit 1; }

python3 - "$SWAGGER" <<'PY'
import json, sys
paths = json.load(open(sys.argv[1], encoding='utf-8')).get('paths', {})
required = [
    ('/api/app/canonical-vehicle-admin', 'post'),
    ('/api/app/vehicle-catalog', 'get'),
    ('/api/app/listing-command', 'post'),
    ('/api/identity/users', 'post'),
]
missing = [f'{verb.upper()} {path}' for path, verb in required if verb not in paths.get(path, {})]
if missing:
    raise SystemExit(f'Canonical catalog contract missing from Swagger: {missing}; available={sorted(paths)}')
PY
echo 'CANONICAL_CATALOG_ROUTES: PASS'

CREATE_BODY="$(python3 - <<'PY'
import json
print(json.dumps({
  'brandName': 'Bom Pra Ti Motors',
  'modelName': 'MVP One',
  'generationName': 'G1',
  'generationStartYear': 2024,
  'generationEndYear': 2026,
  'versionName': '1.0 Turbo',
  'modelYear': 2026,
}))
PY
)"

status="$(request_json POST '/api/app/canonical-vehicle-admin' '' "$CREATE_BODY")"
[[ "$status" == 401 ]] || { echo "Anonymous canonical create expected 401 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'CANONICAL_CATALOG_ANONYMOUS_BLOCKED: PASS'

ADMIN_TOKEN="$(token admin '1q2w3E*')"
USER="canonical-seller-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:10])')"
USER_PASSWORD='Bpt2-Canonical-9!x'
USER_BODY="$(python3 - "$USER" "$USER_PASSWORD" <<'PY'
import json,sys
username,password=sys.argv[1:]
print(json.dumps({
  'userName': username,
  'name': 'Canonical',
  'surname': 'Seller',
  'email': f'{username}@example.invalid',
  'password': password,
  'isActive': True,
  'lockoutEnabled': True,
  'roleNames': [],
}))
PY
)"
status="$(request_json POST '/api/identity/users' "$ADMIN_TOKEN" "$USER_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Seller user create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
USER_TOKEN="$(token "$USER" "$USER_PASSWORD")"

status="$(request_json POST '/api/app/canonical-vehicle-admin' "$USER_TOKEN" "$CREATE_BODY")"
[[ "$status" == 403 ]] || { echo "Non-admin canonical create expected 403 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo 'CANONICAL_CATALOG_NON_ADMIN_BLOCKED: PASS'

status="$(request_json POST '/api/app/canonical-vehicle-admin' "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Admin canonical create expected 200/201 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
VEHICLE_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
assert data['brand'] == 'Bom Pra Ti Motors', data
assert data['model'] == 'MVP One', data
assert data['generation'] == 'G1', data
assert data['version'] == '1.0 Turbo', data
assert data['modelYear'] == 2026, data
print(data['id'])
PY
)"
[[ -n "$VEHICLE_ID" ]] || { echo 'Canonical create returned empty VehicleId.' >&2; exit 1; }
echo 'CANONICAL_CATALOG_ADMIN_CREATE: PASS'

status="$(request_json POST '/api/app/canonical-vehicle-admin' "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Idempotent canonical create expected 200/201 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
SECOND_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"
[[ "${SECOND_ID,,}" == "${VEHICLE_ID,,}" ]] || { echo "Canonical repeat changed VehicleId: $VEHICLE_ID -> $SECOND_ID" >&2; exit 1; }
echo 'CANONICAL_CATALOG_IDEMPOTENT: PASS'

status="$(request_json GET '/api/app/vehicle-catalog?take=100')"
[[ "$status" == 200 ]] || { echo "Public catalog expected 200 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$VEHICLE_ID" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
vehicle_id=sys.argv[2].lower()
if not any(str(item.get('id','')).lower() == vehicle_id for item in data):
    raise SystemExit(f'Created Vehicle {vehicle_id} missing from public catalog: {data}')
PY
echo 'CANONICAL_CATALOG_PUBLIC_READ: PASS'

DRAFT_BODY="$(python3 - "$VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId': sys.argv[1],
  'title': 'Draft sem fixture de catálogo',
  'price': 125000,
  'description': 'Criado usando Vehicle canônico inserido pela superfície admin.',
  'manufactureYear': 2025,
  'mileageKm': 1200,
  'color': 'Prata',
  'city': 'São Paulo',
  'stateCode': 'SP',
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$USER_TOKEN" "$DRAFT_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Seller Draft without fixture expected 200/201 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$VEHICLE_ID" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
assert data['status'] == 'Draft', data
assert str(data['vehicleId']).lower() == sys.argv[2].lower(), data
PY
echo 'CANONICAL_CATALOG_SELLER_DRAFT: PASS'

status="$(curl --silent --show-error --output "$PAGE_HTML" --dump-header "$HEADERS" --write-out '%{http_code}' "$BASE/catalogo")"
[[ "$status" == 302 ]] || { echo "Anonymous catalog page expected 302 got $status" >&2; exit 1; }
grep -Fqi '/Account/Login' "$HEADERS" || { echo 'Anonymous catalog page did not redirect to login.' >&2; cat "$HEADERS" >&2; exit 1; }
echo 'CANONICAL_CATALOG_PAGE_ANONYMOUS_BLOCKED: PASS'

login_cookie admin '1q2w3E*' "$ADMIN_COOKIES"
status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/admin")"
[[ "$status" == 200 ]] || { echo "Admin hub expected 200 got $status" >&2; exit 1; }
grep -Fq 'href="/catalogo"' "$PAGE_HTML" || { echo 'Canonical catalog link missing from admin hub.' >&2; exit 1; }

status="$(curl --silent --show-error --output "$PAGE_HTML" --cookie "$ADMIN_COOKIES" --write-out '%{http_code}' "$BASE/catalogo")"
[[ "$status" == 200 ]] || { echo "Canonical catalog page expected 200 got $status" >&2; exit 1; }
grep -Fq 'Catálogo canônico' "$PAGE_HTML" || { echo 'Canonical catalog page title missing.' >&2; exit 1; }
grep -Fq 'action="/catalogo?handler=Create"' "$PAGE_HTML" || { echo 'Canonical catalog create form missing.' >&2; exit 1; }
echo 'CANONICAL_CATALOG_ADMIN_PAGE: PASS'

echo 'ADMIN CANONICAL CATALOG HTTP: PASSED'
