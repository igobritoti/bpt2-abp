#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5096}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-seller-draft-edit.log"
RESPONSE="${TMPDIR:-/tmp}/bpt2-seller-draft-edit-response.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" -o "$RESPONSE"; then
    break
  fi
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$RESPONSE" ]] || { cat "$LOG" >&2; echo "Swagger did not become available." >&2; exit 1; }

python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    paths = json.load(handle).get("paths", {})
required = [
    ("/api/app/vehicle-catalog", "get"),
    ("/api/app/listing-command", "post"),
    ("/api/app/listing-command", "put"),
    ("/api/app/seller-listing-query/mine-by-id/{listingId}", "get"),
    ("/api/identity/users", "post"),
]
missing = [f"{verb.upper()} {path}" for path, verb in required if verb not in paths.get(path, {})]
if missing:
    raise SystemExit(f"Seller Draft/Edit frontend contract does not match Swagger: {missing}; available={sorted(paths)}")
update = paths["/api/app/listing-command"]["put"]
parameters = update.get("parameters", [])
if not any(p.get("in") == "query" and p.get("name", "").lower() == "listingid" for p in parameters):
    raise SystemExit(f"Listing update must expose listingId as query parameter: {parameters}")
PY
echo "SELLER_DRAFT_EDIT_ROUTES: PASS"

get_token() {
  local username="$1" password="$2" token_file="${TMPDIR:-/tmp}/bpt2-draft-token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$BASE/connect/token" \
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

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$BASE$path"
}

status="$(request_json GET '/api/app/vehicle-catalog?take=50')"
[[ "$status" == "200" ]] || { echo "Vehicle catalog expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
vehicle_id = sys.argv[2].lower()
if not isinstance(data, list):
    raise SystemExit(f"Vehicle catalog must be an array: {data}")
if not any(str(item.get("id", "")).lower() == vehicle_id for item in data):
    raise SystemExit(f"Canonical fixture Vehicle {vehicle_id} missing from catalog: {data}")
PY
echo "SELLER_DRAFT_EDIT_CANONICAL_VEHICLE: PASS"

OWNER_TOKEN="$(get_token admin '1q2w3E*')"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": "Seller Draft Edit",
    "price": 148500,
    "description": "Draft criado pelo checkpoint Seller Draft/Edit.",
    "manufactureYear": 2024,
    "mileageKm": 8200,
    "color": "Azul",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$OWNER_TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Draft create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
read -r LISTING_ID ORIGINAL_STAMP STATUS < <(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
print(data["id"], data["concurrencyStamp"], data["status"])
PY
)
[[ "$STATUS" == "Draft" ]] || { echo "New Listing must be Draft, got $STATUS" >&2; exit 1; }
[[ -n "$ORIGINAL_STAMP" ]] || { echo "Draft returned empty ConcurrencyStamp" >&2; exit 1; }
echo "SELLER_DRAFT_EDIT_CREATE: PASS"

DETAIL_PATH="/api/app/seller-listing-query/mine-by-id/$LISTING_ID"
status="$(request_json GET "$DETAIL_PATH" "$OWNER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owned edit read expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" "$BPT_FIXTURE_VEHICLE_ID" "$ORIGINAL_STAMP" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
listing_id, vehicle_id, stamp = (value.lower() for value in sys.argv[2:5])
listing = data.get("listing")
if not isinstance(listing, dict):
    raise SystemExit(f"Owned detail missing listing: {data}")
if str(listing.get("id", "")).lower() != listing_id:
    raise SystemExit(f"Owned detail Listing mismatch: {data}")
if str(listing.get("vehicleId", "")).lower() != vehicle_id:
    raise SystemExit(f"Owned detail Vehicle mismatch: {data}")
if str(listing.get("concurrencyStamp", "")).lower() != stamp:
    raise SystemExit(f"Owned detail ConcurrencyStamp mismatch: {data}")
photos = data.get("photos")
if photos != []:
    raise SystemExit(f"New Draft gallery expected [], got: {photos}")
PY
echo "SELLER_DRAFT_EDIT_OWNED_READ: PASS"

OTHER_USER="seller-edit-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:10])
PY
)"
OTHER_PASSWORD='Bpt2-OtherSeller-9!x'
OTHER_EMAIL="${OTHER_USER}@example.invalid"
OTHER_BODY="$(python3 - "$OTHER_USER" "$OTHER_EMAIL" "$OTHER_PASSWORD" <<'PY'
import json, sys
username, email, password = sys.argv[1:]
print(json.dumps({
    "userName": username,
    "name": "Other",
    "surname": "Seller",
    "email": email,
    "password": password,
    "isActive": True,
    "lockoutEnabled": True,
    "roleNames": []
}))
PY
)"
status="$(request_json POST '/api/identity/users' "$OWNER_TOKEN" "$OTHER_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Second Seller create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
OTHER_TOKEN="$(get_token "$OTHER_USER" "$OTHER_PASSWORD")"
status="$(request_json GET "$DETAIL_PATH" "$OTHER_TOKEN")"
[[ "$status" == "204" || "$status" == "404" ]] || { echo "Cross-Seller edit read expected hidden 204/404, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "SELLER_DRAFT_EDIT_OWNERSHIP: PASS"

UPDATE_BODY="$(python3 - "$ORIGINAL_STAMP" <<'PY'
import json, sys
print(json.dumps({
    "title": "Seller Draft Edit Updated",
    "price": 149900,
    "concurrencyStamp": sys.argv[1],
    "description": "Draft atualizado pelo owner.",
    "manufactureYear": 2024,
    "mileageKm": 8100,
    "color": "Azul",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
UPDATE_PATH="/api/app/listing-command?listingId=$LISTING_ID"
status="$(request_json PUT "$UPDATE_PATH" "$OWNER_TOKEN" "$UPDATE_BODY")"
[[ "$status" == "200" ]] || { echo "Owner edit expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
NEW_STAMP="$(python3 - "$RESPONSE" "$ORIGINAL_STAMP" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("title") != "Seller Draft Edit Updated":
    raise SystemExit(f"Updated title mismatch: {data}")
new_stamp = data.get("concurrencyStamp")
if not new_stamp or new_stamp == sys.argv[2]:
    raise SystemExit(f"Update did not rotate ConcurrencyStamp: {data}")
print(new_stamp)
PY
)"
echo "SELLER_DRAFT_EDIT_UPDATE: PASS"

STALE_BODY="$(python3 - "$ORIGINAL_STAMP" <<'PY'
import json, sys
print(json.dumps({
    "title": "Seller Draft Edit Stale",
    "price": 150000,
    "concurrencyStamp": sys.argv[1],
    "description": "Stale update must fail.",
    "manufactureYear": 2024,
    "mileageKm": 8000,
    "color": "Azul",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json PUT "$UPDATE_PATH" "$OWNER_TOKEN" "$STALE_BODY")"
[[ "$status" == "409" ]] || { echo "Stale edit expected 409, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "SELLER_DRAFT_EDIT_STALE_CONCURRENCY: PASS"

status="$(request_json GET "$DETAIL_PATH" "$OWNER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owned edit reread expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$NEW_STAMP" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
listing = data["listing"]
if listing.get("title") != "Seller Draft Edit Updated" or listing.get("concurrencyStamp") != sys.argv[2]:
    raise SystemExit(f"Owned reread did not return updated canonical state: {data}")
PY
echo "SELLER_DRAFT_EDIT_REREAD: PASS"

echo "SELLER DRAFT EDIT HTTP: PASSED"
