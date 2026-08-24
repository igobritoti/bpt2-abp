#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5104}"
WEB_PORT="${BPT_PUBLIC_SELLER_WEB_PORT:-3104}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-seller-hub"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
RESPONSE="$TMP/response.json"
DETAIL_HTML="$TMP/detail.html"
SELLER_HTML="$TMP/seller.html"

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
  local username="$1" password="$2"
  local token_file="$TMP/token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token request for $username failed: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Token response missing access_token")
print(token)
PY
}

create_user() {
  local admin_token="$1" username="$2" email="$3" password="$4" name="$5"
  local body status
  body="$(python3 - "$username" "$email" "$password" "$name" <<'PY'
import json, sys
username, email, password, name = sys.argv[1:]
print(json.dumps({
    "userName": username,
    "name": name,
    "surname": "Seller",
    "email": email,
    "password": password,
    "isActive": True,
    "lockoutEnabled": True,
    "roleNames": []
}))
PY
)"
  status="$(request_json POST '/api/identity/users' "$admin_token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Identity user create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
}

upsert_profile() {
  local token="$1" display_name="$2" whatsapp="$3"
  local body status
  body="$(python3 - "$display_name" "$whatsapp" <<'PY'
import json, sys
print(json.dumps({"displayName": sys.argv[1], "whatsAppNumber": sys.argv[2]}))
PY
)"
  status="$(request_json POST '/api/app/seller-profile/upsert' "$token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile upsert failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
print(data["id"])
PY
}

create_listing() {
  local token="$1" title="$2" price="$3"
  local body status
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": sys.argv[2],
    "price": float(sys.argv[3]),
    "description": "Fixture do Public Seller Hub.",
    "manufactureYear": 2024,
    "mileageKm": 9000,
    "color": "Prata",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$token" "$body")"
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
  local token="$1" listing_id="$2" status
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$token")"
  [[ "$status" == "200" ]] || { echo "Listing publish failed: $status $(cat "$RESPONSE")" >&2; return 1; }
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

ADMIN_TOKEN="$(get_token admin '1q2w3E*')"
SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:10])
PY
)"
OWNER_USER="seller-hub-owner-$SUFFIX"
OTHER_USER="seller-hub-other-$SUFFIX"
OWNER_PASSWORD='Bpt2-SellerHub-Owner-9!x'
OTHER_PASSWORD='Bpt2-SellerHub-Other-9!x'
OWNER_NAME="Seller Hub Owner $SUFFIX"
OTHER_NAME="Seller Hub Other $SUFFIX"

create_user "$ADMIN_TOKEN" "$OWNER_USER" "$OWNER_USER@example.invalid" "$OWNER_PASSWORD" "HubOwner"
create_user "$ADMIN_TOKEN" "$OTHER_USER" "$OTHER_USER@example.invalid" "$OTHER_PASSWORD" "HubOther"
OWNER_TOKEN="$(get_token "$OWNER_USER" "$OWNER_PASSWORD")"
OTHER_TOKEN="$(get_token "$OTHER_USER" "$OTHER_PASSWORD")"
OWNER_ID="$(upsert_profile "$OWNER_TOKEN" "$OWNER_NAME" '+55 (11) 95555-1101')"
OTHER_ID="$(upsert_profile "$OTHER_TOKEN" "$OTHER_NAME" '+55 (11) 95555-2202')"
[[ "$OWNER_ID" != "$OTHER_ID" ]] || { echo "Seller fixture ids must differ" >&2; exit 1; }

echo "PUBLIC_SELLER_HUB_SELLERS: PASS"

OWNER_TITLE="Seller Hub Public $SUFFIX"
OWNER_DRAFT_TITLE="Seller Hub Draft $SUFFIX"
OTHER_TITLE="Seller Hub Other Public $SUFFIX"
OWNER_LISTING_ID="$(create_listing "$OWNER_TOKEN" "$OWNER_TITLE" 135000)"
OWNER_DRAFT_ID="$(create_listing "$OWNER_TOKEN" "$OWNER_DRAFT_TITLE" 136000)"
OTHER_LISTING_ID="$(create_listing "$OTHER_TOKEN" "$OTHER_TITLE" 145000)"
publish_listing "$OWNER_TOKEN" "$OWNER_LISTING_ID"
publish_listing "$OTHER_TOKEN" "$OTHER_LISTING_ID"

echo "PUBLIC_SELLER_HUB_FIXTURES: PASS"

status="$(request_json GET "/api/app/public-listing?SellerId=$OWNER_ID&Take=24")"
[[ "$status" == "200" ]] || { echo "SellerId public query expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$OWNER_ID" "$OWNER_LISTING_ID" "$OWNER_DRAFT_ID" "$OTHER_LISTING_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
owner_id, owner_listing_id, owner_draft_id, other_listing_id = (value.lower() for value in sys.argv[2:6])
items = data.get("items") or []
ids = {str(item.get("id", "")).lower() for item in items}
if data.get("totalCount") != 1:
    raise SystemExit(f"Seller filter expected totalCount=1: {data}")
if ids != {owner_listing_id}:
    raise SystemExit(f"Seller filter returned wrong Listings: {data}")
item = items[0]
if str((item.get("seller") or {}).get("sellerId", "")).lower() != owner_id:
    raise SystemExit(f"Seller projection mismatch: {data}")
if owner_draft_id in ids or other_listing_id in ids:
    raise SystemExit(f"Seller filter leaked Draft/other Seller: {data}")
PY
echo "PUBLIC_SELLER_HUB_API_FILTER: PASS"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 &
WEB_PID=$!
popd >/dev/null

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$WEB_BASE" >/dev/null; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$OWNER_LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Owner detail expected 200, got $status" >&2; exit 1; }
grep -Fq "$OWNER_NAME" "$DETAIL_HTML" || { echo "Owner display name missing from detail" >&2; exit 1; }
grep -Fq "/vendedores/$OWNER_ID" "$DETAIL_HTML" || { echo "Seller Hub link missing from detail" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_DETAIL_LINK: PASS"

status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$OWNER_ID")"
[[ "$status" == "200" ]] || { echo "Seller Hub expected 200, got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }
grep -Fq "$OWNER_NAME" "$SELLER_HTML" || { echo "Seller Hub display name missing" >&2; exit 1; }
grep -Fq "$OWNER_TITLE" "$SELLER_HTML" || { echo "Seller Hub owner Listing missing" >&2; exit 1; }
grep -Fq "/anuncios/$OWNER_LISTING_ID" "$SELLER_HTML" || { echo "Seller Hub Listing link missing" >&2; exit 1; }
if grep -Fq "$OWNER_DRAFT_TITLE" "$SELLER_HTML"; then echo "Seller Hub leaked owner Draft" >&2; exit 1; fi
if grep -Fq "$OTHER_TITLE" "$SELLER_HTML"; then echo "Seller Hub leaked other Seller Listing" >&2; exit 1; fi
grep -Fq "<title>$OWNER_NAME | Bom Pra Ti</title>" "$SELLER_HTML" || { echo "Seller Hub metadata title missing" >&2; exit 1; }
grep -Fq "href=\"$WEB_BASE/vendedores/$OWNER_ID\"" "$SELLER_HTML" || { echo "Seller Hub canonical missing" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_VISIBLE: PASS"
echo "PUBLIC_SELLER_HUB_ISOLATED: PASS"

UNKNOWN_ID="00000000-0000-4000-8000-000000000001"
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$UNKNOWN_ID")"
[[ "$status" == "404" ]] || { echo "Unknown Seller Hub expected 404, got $status" >&2; exit 1; }
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/not-a-guid")"
[[ "$status" == "404" ]] || { echo "Invalid Seller Hub id expected 404, got $status" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_UNKNOWN_HIDDEN: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$OWNER_LISTING_ID" "$OWNER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner Listing pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json GET "/api/app/public-listing?SellerId=$OWNER_ID&Take=24")"
[[ "$status" == "200" ]] || { echo "Paused SellerId public query expected 200, got $status" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("totalCount") != 0 or data.get("items") not in ([], None):
    raise SystemExit(f"Paused Seller must have no public Listings: {data}")
PY
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$OWNER_ID")"
[[ "$status" == "404" ]] || { echo "Seller Hub without public Listing expected 404, got $status" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_EMPTY_HIDDEN: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$OTHER_LISTING_ID" "$OTHER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Other Seller Listing cleanup failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_FIXTURES_CLEANED: PASS"

echo "PUBLIC SELLER HUB HTTP: PASSED"
