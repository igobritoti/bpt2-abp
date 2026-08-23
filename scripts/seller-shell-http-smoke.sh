#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5095}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-seller-shell.log"
RESPONSE="${TMPDIR:-/tmp}/bpt2-seller-shell-response.json"

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

get_token() {
  local token_file="${TMPDIR:-/tmp}/bpt2-seller-shell-token.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || {
    echo "Admin token expected 200, got $status: $(cat "$token_file")" >&2
    return 1
  }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle).get("access_token")
if not value:
    raise SystemExit("Token response did not contain access_token")
print(value)
PY
}

request_json() {
  local method="$1" path="$2" token="$3" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method" \
    -H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$BASE$path"
}

TOKEN="$(get_token)"

PROFILE_INPUT='{"displayName":"BPT Seller Shell","whatsAppNumber":"+55 (11) 98888-7766"}'
status="$(request_json POST '/api/app/seller-profile/upsert' "$TOKEN" "$PROFILE_INPUT")"
[[ "$status" == "200" || "$status" == "201" ]] || {
  echo "Seller profile upsert expected 200/201, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("displayName") != "BPT Seller Shell":
    raise SystemExit(f"Unexpected Seller displayName: {data}")
if data.get("whatsAppNumber") != "5511988887766":
    raise SystemExit(f"Seller WhatsApp was not canonicalized: {data}")
PY
echo "SELLER_SHELL_PROFILE_UPSERT: PASS"

status="$(request_json GET '/api/app/seller-profile/current' "$TOKEN")"
[[ "$status" == "200" ]] || {
  echo "Seller profile current expected 200, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("displayName") != "BPT Seller Shell" or data.get("whatsAppNumber") != "5511988887766":
    raise SystemExit(f"Seller current profile mismatch: {data}")
PY
echo "SELLER_SHELL_PROFILE_CURRENT: PASS"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": "Seller Shell Draft",
    "price": 135000,
    "description": "Draft created to prove the authenticated Seller shell query.",
    "manufactureYear": 2024,
    "mileageKm": 12000,
    "color": "Cinza",
    "city": "São Paulo",
    "stateCode": "SP"
}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || {
  echo "Seller Listing create expected 200/201, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft":
    raise SystemExit(f"New Seller Listing must be Draft: {data}")
print(data["id"])
PY
)"
echo "SELLER_SHELL_DRAFT_CREATE: PASS"

status="$(request_json GET '/api/app/seller-listing-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || {
  echo "My Listings expected 200, got $status: $(cat "$RESPONSE")" >&2
  exit 1
}
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json, sys
path, listing_id = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
if not isinstance(data, list):
    raise SystemExit(f"My Listings response must be an array: {data}")
match = next((item for item in data if str(item.get("id", "")).lower() == listing_id.lower()), None)
if match is None:
    raise SystemExit(f"Created Listing {listing_id} missing from My Listings: {data}")
if match.get("title") != "Seller Shell Draft" or match.get("status") != "Draft":
    raise SystemExit(f"My Listings projection mismatch: {match}")
if not match.get("concurrencyStamp"):
    raise SystemExit(f"My Listings did not preserve concurrencyStamp: {match}")
PY
echo "SELLER_SHELL_MY_LISTINGS: PASS"

echo "SELLER SHELL HTTP: PASSED"
