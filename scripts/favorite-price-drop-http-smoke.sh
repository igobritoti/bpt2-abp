#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5108}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-favorite-price-drop"
LOG="$TMP/api.log"
RESPONSE="$TMP/response.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"
export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false

API_PID=""
cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$BASE$path"
}

get_token() {
  local username="$1"
  local password="$2"
  local token_file="$TMP/token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token failed for $username: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['access_token'])
PY
}

create_buyer() {
  local username="$1"
  local password="$2"
  local email="${username}@example.invalid"
  local body status
  body="$(python3 - "$username" "$email" "$password" <<'PY'
import json,sys
print(json.dumps({'userName':sys.argv[1],'name':'Price','surname':'Drop','email':sys.argv[2],'password':sys.argv[3],'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
  status="$(request_json POST '/api/identity/users' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Buyer create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'].replace('-','').lower())
PY
}

update_price() {
  local listing_id="$1" stamp="$2" price="$3" body status
  body="$(python3 - "$stamp" "$price" <<'PY'
import json,sys
print(json.dumps({'title':'Favorite Price Drop Fixture','price':float(sys.argv[2]),'concurrencyStamp':sys.argv[1],'description':'Favorite price-drop contract fixture.','manufactureYear':2024,'mileageKm':12000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
  status="$(request_json PUT "/api/app/listing-command?listingId=$listing_id" "$ADMIN_TOKEN" "$body")"
  [[ "$status" == "200" ]] || { echo "Price update failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['concurrencyStamp'])
PY
}

fixture_state() {
  local command="$1" listing_id="$2" output
  output="$(dotnet run --project "$ROOT/tests/BomPraTi.PriceDropFixture/BomPraTi.PriceDropFixture.csproj" --configuration Release -- "$command" "$listing_id")"
  printf '%s\n' "$output" | sed -n 's/^PRICE_DROP_STATE://p' | tail -n 1
}

price_drop_state() {
  fixture_state state "$1"
}

replay_price_drop() {
  fixture_state replay "$1"
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" >/dev/null && break
  kill -0 "$API_PID" >/dev/null 2>&1 || { cat "$LOG" >&2; exit 1; }
  sleep 1
done
curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" >/dev/null

ADMIN_TOKEN="$(get_token admin '1q2w3E*')"
status="$(request_json POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Price Drop Seller","whatsAppNumber":"5511999992222"}')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

BUYER1_USER="price-drop-a-$(python3 - <<'PY'
import uuid; print(uuid.uuid4().hex[:10])
PY
)"
BUYER2_USER="price-drop-b-$(python3 - <<'PY'
import uuid; print(uuid.uuid4().hex[:10])
PY
)"
BUYER_PASSWORD='Bpt2-PriceDrop-9!x'
BUYER1_ID="$(create_buyer "$BUYER1_USER" "$BUYER_PASSWORD")"
BUYER2_ID="$(create_buyer "$BUYER2_USER" "$BUYER_PASSWORD")"
BUYER1_TOKEN="$(get_token "$BUYER1_USER" "$BUYER_PASSWORD")"
BUYER2_TOKEN="$(get_token "$BUYER2_USER" "$BUYER_PASSWORD")"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Favorite Price Drop Fixture','price':200000,'description':'Favorite price-drop contract fixture.','manufactureYear':2024,'mileageKm':12000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
read -r LISTING_ID STAMP < <(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1], encoding='utf-8')); print(x['id'],x['concurrencyStamp'])
PY
)

STAMP="$(update_price "$LISTING_ID" "$STAMP" 195000)"
[[ -z "$(price_drop_state "$LISTING_ID")" ]] || { echo "Draft decrease produced price-drop ledger" >&2; exit 1; }
echo "FAVORITE_PRICE_DROP_DRAFT_IGNORED: PASS"

status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
STAMP="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1], encoding='utf-8'))['concurrencyStamp'])
PY
)"
FAVORITE_PATH="/api/app/favorite?listingId=$LISTING_ID"
status="$(request_json POST "$FAVORITE_PATH" "$BUYER1_TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Buyer1 favorite failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

STAMP="$(update_price "$LISTING_ID" "$STAMP" 180000)"
EXPECTED1="$BUYER1_ID|195000.00>180000.00"
STATE="$(price_drop_state "$LISTING_ID")"
[[ "$STATE" == "$EXPECTED1" ]] || { echo "First price-drop match mismatch: $STATE" >&2; exit 1; }
echo "FAVORITE_PRICE_DROP_EXISTING_FAVORITE: PASS"

status="$(request_json POST "$FAVORITE_PATH" "$BUYER2_TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Buyer2 favorite failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
[[ "$(price_drop_state "$LISTING_ID")" == "$EXPECTED1" ]] || { echo "Late favorite received retroactive price drop" >&2; exit 1; }
echo "FAVORITE_PRICE_DROP_NO_RETROACTIVE_MATCH: PASS"

[[ "$(replay_price_drop "$LISTING_ID")" == "$EXPECTED1" ]] || { echo "Price-drop replay duplicated ledger" >&2; exit 1; }
echo "FAVORITE_PRICE_DROP_REPLAY_IDEMPOTENT: PASS"

STAMP="$(update_price "$LISTING_ID" "$STAMP" 190000)"
STATE="$(price_drop_state "$LISTING_ID")"
[[ "$STATE" == "$EXPECTED1" ]] || { echo "Price increase changed price-drop ledger: $STATE" >&2; exit 1; }
echo "FAVORITE_PRICE_DROP_INCREASE_IGNORED: PASS"

status="$(request_json DELETE "$FAVORITE_PATH" "$BUYER1_TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Buyer1 unfavorite failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
STAMP="$(update_price "$LISTING_ID" "$STAMP" 170000)"
STATE="$(price_drop_state "$LISTING_ID")"
python3 - "$STATE" "$BUYER1_ID" "$BUYER2_ID" <<'PY'
import sys
state,buyer1,buyer2=sys.argv[1:]
rows=state.split(';') if state else []
expected={f'{buyer1}|195000.00>180000.00',f'{buyer2}|190000.00>170000.00'}
if set(rows) != expected or len(rows) != 2:
    raise SystemExit(f'Unexpected price-drop ledger after unfavorite: {rows}')
PY
echo "FAVORITE_PRICE_DROP_UNFAVORITE_STOPS_FUTURE_MATCH: PASS"
echo "FAVORITE PRICE DROP HTTP: PASSED"
