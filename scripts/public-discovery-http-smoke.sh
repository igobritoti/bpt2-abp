#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5099}"
WEB_PORT="${BPT_PUBLIC_DISCOVERY_WEB_PORT:-3099}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-discovery"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
RESPONSE="$TMP/response.json"
PAGE_ONE="$TMP/page-one.html"
PAGE_TWO="$TMP/page-two.html"
FILTERED="$TMP/filtered.html"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false

API_PID=""
WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$API_BASE$path"
}

get_token() {
  local token_file="$TMP/token.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Admin token expected 200, got $status: $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Token response missing access_token")
print(token)
PY
}

create_listing() {
  local title="$1" price="$2" city="$3" state_code="$4"
  local body status
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" "$city" "$state_code" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": sys.argv[2],
    "price": float(sys.argv[3]),
    "description": "Fixture de discovery público.",
    "manufactureYear": 2024,
    "mileageKm": 10000,
    "color": "Cinza",
    "city": sys.argv[4],
    "stateCode": sys.argv[5]
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft":
    raise SystemExit(f"Listing must start Draft: {data}")
print(data["id"])
PY
}

publish_listing() {
  local listing_id="$1" status
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$ADMIN_TOKEN")"
  [[ "$status" == "200" ]] || { echo "Listing publish failed: $status $(cat "$RESPONSE")" >&2; return 1; }
}

assert_visible_text() {
  local html_file="$1" expected="$2"
  python3 - "$html_file" "$expected" <<'PY'
from html.parser import HTMLParser
import sys

class VisibleText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)

parser = VisibleText()
with open(sys.argv[1], encoding="utf-8") as handle:
    parser.feed(handle.read())
visible = "".join(parser.parts)
expected = sys.argv[2]
if expected not in visible:
    raise SystemExit(f"Visible HTML text missing {expected!r}; text={visible!r}")
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null; then
    break
  fi
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then
    cat "$API_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_token)"
PROFILE='{"displayName":"Discovery Seller","whatsAppNumber":"+55 (11) 96666-5544"}'
status="$(request_json POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" "$PROFILE")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request_json GET "/api/app/vehicle-catalog/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == "200" ]] || { echo "Vehicle fixture lookup failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
IFS=$'\t' read -r VEHICLE_BRAND VEHICLE_MODEL VEHICLE_YEAR < <(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
print(f"{data['brand']}\t{data['model']}\t{data.get('modelYear') or ''}")
PY
)
[[ -n "$VEHICLE_BRAND" && -n "$VEHICLE_MODEL" && -n "$VEHICLE_YEAR" ]] || {
  echo "Vehicle fixture must expose brand/model/modelYear for discovery proof" >&2
  exit 1
}

ALPHA_TITLE="Discovery Alpha"
BETA_TITLE="Discovery Beta"
GAMMA_TITLE="Discovery Gamma"
HIDDEN_TITLE="Discovery Hidden Draft"
ALPHA_ID="$(create_listing "$ALPHA_TITLE" 101000 'São Paulo' SP)"
BETA_ID="$(create_listing "$BETA_TITLE" 202000 Curitiba PR)"
GAMMA_ID="$(create_listing "$GAMMA_TITLE" 303000 Campinas SP)"
create_listing "$HIDDEN_TITLE" 404000 'Belo Horizonte' MG >/dev/null
publish_listing "$ALPHA_ID"
publish_listing "$BETA_ID"
publish_listing "$GAMMA_ID"
echo "PUBLIC_DISCOVERY_FIXTURES: PASS"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$WEB_BASE" -o "$PAGE_ONE"; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE" -o "$PAGE_ONE" || { cat "$WEB_LOG" >&2; exit 1; }

for field in query brand model city stateCode minModelYear maxModelYear minPrice maxPrice; do
  grep -Fq "name=\"$field\"" "$PAGE_ONE" || { echo "Discovery form missing $field" >&2; exit 1; }
done
echo "PUBLIC_DISCOVERY_FORM: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'query=Discovery' \
  --data-urlencode 'stateCode=sp' \
  --data-urlencode 'take=1' \
  -o "$PAGE_ONE"

assert_visible_text "$PAGE_ONE" '2 anúncio(s)'
if grep -Fq "$BETA_TITLE" "$PAGE_ONE" || grep -Fq "$HIDDEN_TITLE" "$PAGE_ONE"; then
  echo "State-filtered pagination leaked non-SP or Draft listing" >&2
  exit 1
fi

NEXT_HREF="$(python3 - "$PAGE_ONE" <<'PY'
from html.parser import HTMLParser
from urllib.parse import parse_qs, urlparse
import sys
class Parser(HTMLParser):
    href = None
    current = None
    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self.current = dict(attrs).get("href")
    def handle_endtag(self, tag):
        if tag == "a":
            self.current = None
    def handle_data(self, data):
        if self.current and "Próxima" in data:
            self.href = self.current
parser = Parser()
with open(sys.argv[1], encoding="utf-8") as handle:
    parser.feed(handle.read())
if not parser.href:
    raise SystemExit("Next pagination link not found")
query = parse_qs(urlparse(parser.href).query)
if query.get("query") != ["Discovery"] or query.get("stateCode") != ["sp"] or query.get("take") != ["1"] or query.get("skip") != ["1"]:
    raise SystemExit(f"Pagination did not preserve location filters: {parser.href}")
print(parser.href)
PY
)"
curl --fail --silent --show-error "$WEB_BASE$NEXT_HREF" -o "$PAGE_TWO"
python3 - "$PAGE_ONE" "$PAGE_TWO" "$ALPHA_TITLE" "$GAMMA_TITLE" "$BETA_TITLE" "$HIDDEN_TITLE" <<'PY'
import sys
texts = []
for path in sys.argv[1:3]:
    with open(path, encoding="utf-8") as handle:
        texts.append(handle.read())
alpha, gamma, beta, hidden = sys.argv[3:]
for index, text in enumerate(texts, start=1):
    present = [title for title in (alpha, gamma) if title in text]
    if len(present) != 1:
        raise SystemExit(f"Page {index} expected exactly one SP fixture, got {present}")
    if beta in text or hidden in text:
        raise SystemExit(f"State-filtered pagination leaked non-SP or Draft fixture on page {index}")
if (alpha in texts[0]) == (alpha in texts[1]):
    raise SystemExit("Pagination pages did not advance to the other SP listing")
PY
echo "PUBLIC_DISCOVERY_PAGINATION: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'query=Alpha' \
  --data-urlencode 'take=1' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '1 anúncio(s)'
grep -Fq "$ALPHA_TITLE" "$FILTERED" || { echo "Query filter missing Alpha" >&2; exit 1; }
if grep -Fq "$BETA_TITLE" "$FILTERED" || grep -Fq "$GAMMA_TITLE" "$FILTERED"; then echo "Query filter leaked another listing" >&2; exit 1; fi
echo "PUBLIC_DISCOVERY_QUERY: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'minPrice=150000' \
  --data-urlencode 'maxPrice=250000' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '1 anúncio(s)'
grep -Fq "$BETA_TITLE" "$FILTERED" || { echo "Price filter missing Beta" >&2; exit 1; }
if grep -Fq "$ALPHA_TITLE" "$FILTERED" || grep -Fq "$GAMMA_TITLE" "$FILTERED"; then echo "Price filter leaked another listing" >&2; exit 1; fi
echo "PUBLIC_DISCOVERY_PRICE: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode "brand=$VEHICLE_BRAND" \
  --data-urlencode "model=$VEHICLE_MODEL" \
  --data-urlencode "minModelYear=$VEHICLE_YEAR" \
  --data-urlencode "maxModelYear=$VEHICLE_YEAR" \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '3 anúncio(s)'
if grep -Fq "$HIDDEN_TITLE" "$FILTERED"; then echo "Catalog filters leaked Draft" >&2; exit 1; fi
echo "PUBLIC_DISCOVERY_CATALOG: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'stateCode=pr' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '1 anúncio(s)'
grep -Fq "$BETA_TITLE" "$FILTERED" || { echo "State filter missing PR listing" >&2; exit 1; }
if grep -Fq "$ALPHA_TITLE" "$FILTERED" || grep -Fq "$GAMMA_TITLE" "$FILTERED" || grep -Fq "$HIDDEN_TITLE" "$FILTERED"; then
  echo "State filter leaked another location or Draft" >&2
  exit 1
fi
echo "PUBLIC_DISCOVERY_STATE: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'city=campinas' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '1 anúncio(s)'
grep -Fq "$GAMMA_TITLE" "$FILTERED" || { echo "City filter missing Campinas listing" >&2; exit 1; }
if grep -Fq "$ALPHA_TITLE" "$FILTERED" || grep -Fq "$BETA_TITLE" "$FILTERED" || grep -Fq "$HIDDEN_TITLE" "$FILTERED"; then
  echo "City filter leaked another location or Draft" >&2
  exit 1
fi
echo "PUBLIC_DISCOVERY_CITY: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'stateCode=sp' \
  --data-urlencode 'minPrice=250000' \
  --data-urlencode 'maxPrice=350000' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '1 anúncio(s)'
grep -Fq "$GAMMA_TITLE" "$FILTERED" || { echo "Combined location+price filter missing Gamma" >&2; exit 1; }
if grep -Fq "$ALPHA_TITLE" "$FILTERED" || grep -Fq "$BETA_TITLE" "$FILTERED" || grep -Fq "$HIDDEN_TITLE" "$FILTERED"; then
  echo "Combined location+price filter leaked another listing" >&2
  exit 1
fi
echo "PUBLIC_DISCOVERY_LOCATION_COMBINED: PASS"

curl --fail --silent --show-error --get "$WEB_BASE/" \
  --data-urlencode 'minPrice=350000' \
  --data-urlencode 'maxPrice=150000' \
  -o "$FILTERED"
assert_visible_text "$FILTERED" '0 anúncio(s)'
grep -Fq 'Nenhum anúncio encontrado.' "$FILTERED" || { echo "Filtered empty state missing" >&2; exit 1; }
echo "PUBLIC_DISCOVERY_INVALID_RANGE: PASS"

echo "PUBLIC DISCOVERY HTTP: PASSED"
