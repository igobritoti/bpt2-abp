#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_VEHICLE_HUB_API_PORT:-5097}"
WEB_PORT="${BPT_VEHICLE_HUB_WEB_PORT:-3097}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-vehicle-hub"
RESPONSE="$TMP/response.json"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
HUB_HTML="$TMP/hub.html"
DETAIL_HTML="$TMP/detail.html"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false

API_PID=""; WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" url="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$url"
}

token() {
  curl --silent --show-error -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(token)"
status="$(request_json POST "$API_BASE/api/app/seller-profile/upsert" "$ADMIN_TOKEN" '{"displayName":"Vehicle Hub Seller","whatsAppNumber":"+55 (11) 98888-7766"}')"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Seller upsert failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

LISTING_TITLE="Vehicle Hub HTTP Listing"
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$LISTING_TITLE" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId':sys.argv[1], 'title':sys.argv[2], 'price':135900,
  'description':'Oferta usada para provar o Vehicle Hub público.',
  'manufactureYear':2024, 'mileageKm':18000, 'color':'Prata',
  'city':'Campinas', 'stateCode':'SP'
}))
PY
)"
status="$(request_json POST "$API_BASE/api/app/listing-command" "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Listing create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['status']=='Draft',x; print(x['id'])
PY
)"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do curl --fail --silent "$WEB_BASE" >/dev/null && break; sleep 1; done
curl --fail --silent "$WEB_BASE" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

UNKNOWN_VEHICLE="$(python3 -c 'import uuid; print(uuid.uuid4())')"
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$UNKNOWN_VEHICLE")"
[[ "$status" == 404 ]] || { echo "Unknown Vehicle Hub expected 404 got $status" >&2; exit 1; }
grep -Fq 'noindex' "$HUB_HTML" || { echo 'Unknown Vehicle Hub is missing noindex metadata' >&2; exit 1; }
echo 'VEHICLE_HUB_UNKNOWN_404: PASS'
echo 'VEHICLE_HUB_UNKNOWN_NOINDEX: PASS'

status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Canonical Vehicle Hub expected 200 got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Model' "$HUB_HTML" || { echo 'Canonical model missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP-G1' "$HUB_HTML" || { echo 'Canonical generation missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Version' "$HUB_HTML" || { echo 'Canonical version missing from Hub' >&2; exit 1; }
grep -Fq '>2025<' "$HUB_HTML" || { echo 'Canonical model year missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Model HTTP Lifecycle Version 2025 | Bom Pra Ti</title>' "$HUB_HTML" || { echo 'Vehicle Hub metadata title missing' >&2; exit 1; }
grep -Fq "rel=\"canonical\" href=\"$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID\"" "$HUB_HTML" || { echo 'Vehicle Hub canonical missing' >&2; exit 1; }
if grep -Fq "$LISTING_TITLE" "$HUB_HTML"; then echo 'Draft Listing leaked into Vehicle Hub' >&2; exit 1; fi
echo 'VEHICLE_HUB_CANONICAL_IDENTITY: PASS'
echo 'VEHICLE_HUB_METADATA: PASS'
echo 'VEHICLE_HUB_DRAFT_PRIVATE: PASS'

status="$(request_json POST "$API_BASE/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing publish failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || exit 1
grep -Fq "$LISTING_TITLE" "$HUB_HTML" || { echo 'Published Listing missing from Vehicle Hub' >&2; exit 1; }
grep -Fq "/anuncios/$LISTING_ID" "$HUB_HTML" || { echo 'Published Listing detail link missing from Vehicle Hub' >&2; exit 1; }
echo 'VEHICLE_HUB_PUBLISHED_VISIBLE: PASS'

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == 200 ]] || { echo "Listing detail expected 200 got $status" >&2; exit 1; }
grep -Fq "/veiculos/$BPT_FIXTURE_VEHICLE_ID" "$DETAIL_HTML" || { echo 'Listing detail does not link to Vehicle Hub' >&2; exit 1; }
echo 'VEHICLE_HUB_LINKED_FROM_LISTING: PASS'

status="$(request_json POST "$API_BASE/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing pause failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Vehicle Hub disappeared after Pause: $status" >&2; exit 1; }
if grep -Fq "$LISTING_TITLE" "$HUB_HTML"; then echo 'Paused Listing remained visible in Vehicle Hub' >&2; exit 1; fi
grep -Fq 'Nenhum anúncio publicado agora.' "$HUB_HTML" || { echo 'Vehicle Hub empty state missing after Pause' >&2; exit 1; }
echo 'VEHICLE_HUB_PAUSE_REMOVES_LISTING: PASS'
echo 'VEHICLE_HUB_PERSISTS_WITHOUT_OFFER: PASS'
echo 'PUBLIC VEHICLE HUB HTTP: PASSED'
