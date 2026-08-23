#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_SELLER_LEADS_API_PORT:-5098}"
API_BASE="http://127.0.0.1:${API_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-seller-leads"
API_LOG="${TMP}/api.log"
RESPONSE="${TMP}/response.json"
SWAGGER="${TMP}/swagger.json"

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
cleanup() {
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
  local username="$1"
  local password="$2"
  local token_file="${TMP}/token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token failed for $username: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Token response missing access_token")
print(token)
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
API_PID=$!
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then break; fi
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then cat "$API_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER" || { cat "$API_LOG" >&2; exit 1; }
python3 - "$SWAGGER" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    paths = json.load(handle).get("paths", {})
if "get" not in paths.get("/api/app/seller-lead-query/mine", {}):
    raise SystemExit(f"Expected GET Seller Lead inbox; available={sorted(paths)}")
if "post" not in paths.get("/api/app/seller-lead-command/mark-contacted/{leadId}", {}):
    raise SystemExit(f"Expected POST Seller Lead follow-up; available={sorted(paths)}")
PY
echo "SELLER_LEADS_ROUTE: PASS"
echo "SELLER_LEADS_FOLLOW_UP_ROUTE: PASS"

TOKEN="$(get_token admin '1q2w3E*')"
status="$(request_json GET '/api/app/seller-lead-query/mine')"
[[ "$status" == "401" ]] || { echo "Anonymous Seller lead inbox expected 401, got $status" >&2; exit 1; }
echo "SELLER_LEADS_ANONYMOUS_BLOCKED: PASS"

status="$(request_json POST '/api/app/seller-profile/upsert' "$TOKEN" '{"displayName":"Seller Lead Inbox","whatsAppNumber":"+55 (11) 96666-5544"}')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Profile upsert failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({"vehicleId": sys.argv[1], "title": "Seller Lead Inbox Listing", "price": 175000, "description": "Listing para prova de inbox de Leads.", "manufactureYear": 2024, "mileageKm": 8000, "color": "Azul", "city": "São Paulo", "stateCode": "SP"}))
PY
)"
status="$(request_json POST '/api/app/listing-command' "$TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: print(json.load(handle)["id"])
PY
)"
status="$(request_json POST "/api/app/listing-command/publish/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Publish failed: $status $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request_json POST "/api/app/lead?listingId=$LISTING_ID")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Anonymous Lead create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
LEAD_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
if data.get("userId") is not None or data.get("channel") != "WhatsApp": raise SystemExit(data)
print(data["id"])
PY
)"

status="$(request_json GET '/api/app/seller-lead-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner lead inbox failed: $status $(cat "$RESPONSE")" >&2; cat "$API_LOG" >&2; exit 1; }
python3 - "$RESPONSE" "$LEAD_ID" "$LISTING_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
lead_id, listing_id=sys.argv[2].lower(),sys.argv[3].lower()
match=next((item for item in data if str(item.get("id","")).lower()==lead_id),None)
if not match: raise SystemExit(f"Owner Lead missing: {data}")
if str(match.get("listingId","")).lower()!=listing_id or match.get("listingTitle")!="Seller Lead Inbox Listing" or match.get("channel")!="WhatsApp": raise SystemExit(match)
if match.get("buyerUserId") is not None or not match.get("createdAtUtc") or match.get("contactedAtUtc") is not None: raise SystemExit(match)
PY
echo "SELLER_LEADS_OWNER_VISIBLE: PASS"
echo "SELLER_LEADS_NEW_STATUS: PASS"

status="$(request_json POST "/api/app/seller-lead-command/mark-contacted/$LEAD_ID")"
[[ "$status" == "401" ]] || { echo "Anonymous follow-up expected 401, got $status" >&2; exit 1; }
echo "SELLER_LEADS_FOLLOW_UP_ANONYMOUS_BLOCKED: PASS"

OTHER_USER="seller-leads-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:10])
PY
)"
OTHER_PASSWORD='Bpt2-SellerLeads-9!x'
OTHER_BODY="$(python3 - "$OTHER_USER" "$OTHER_PASSWORD" <<'PY'
import json, sys
username,password=sys.argv[1:]
print(json.dumps({"userName":username,"name":"Other","surname":"Seller","email":f"{username}@example.invalid","password":password,"isActive":True,"lockoutEnabled":True,"roleNames":[]}))
PY
)"
status="$(request_json POST '/api/identity/users' "$TOKEN" "$OTHER_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Second Seller create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
OTHER_TOKEN="$(get_token "$OTHER_USER" "$OTHER_PASSWORD")"
status="$(request_json GET '/api/app/seller-lead-query/mine' "$OTHER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Second Seller inbox failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LEAD_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
if any(str(item.get("id","")).lower()==sys.argv[2].lower() for item in data): raise SystemExit(f"Cross-Seller Lead leaked: {data}")
PY
echo "SELLER_LEADS_OWNERSHIP: PASS"
status="$(request_json POST "/api/app/seller-lead-command/mark-contacted/$LEAD_ID" "$OTHER_TOKEN")"
[[ "$status" == "404" ]] || { echo "Second Seller follow-up expected 404, got $status $(cat "$RESPONSE")" >&2; exit 1; }
echo "SELLER_LEADS_FOLLOW_UP_OWNERSHIP: PASS"

status="$(request_json POST "/api/app/seller-lead-command/mark-contacted/$LEAD_ID" "$TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Owner follow-up failed: $status $(cat "$RESPONSE")" >&2; cat "$API_LOG" >&2; exit 1; }
status="$(request_json GET '/api/app/seller-lead-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner inbox after follow-up failed: $status" >&2; exit 1; }
CONTACTED_AT="$(python3 - "$RESPONSE" "$LEAD_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
match=next((item for item in data if str(item.get("id","")).lower()==sys.argv[2].lower()),None)
if not match or not match.get("contactedAtUtc"): raise SystemExit(f"Contacted timestamp missing: {data}")
print(match["contactedAtUtc"])
PY
)"
echo "SELLER_LEADS_FOLLOW_UP_PERSISTED: PASS"
status="$(request_json POST "/api/app/seller-lead-command/mark-contacted/$LEAD_ID" "$TOKEN")"
[[ "$status" == "200" || "$status" == "204" ]] || { echo "Idempotent follow-up failed: $status" >&2; exit 1; }
status="$(request_json GET '/api/app/seller-lead-query/mine' "$TOKEN")"
python3 - "$RESPONSE" "$LEAD_ID" "$CONTACTED_AT" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
match=next(item for item in data if str(item.get("id","")).lower()==sys.argv[2].lower())
if match.get("contactedAtUtc")!=sys.argv[3]: raise SystemExit(f"Follow-up timestamp changed: {match}")
PY
echo "SELLER_LEADS_FOLLOW_UP_IDEMPOTENT: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$LISTING_ID" "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json GET '/api/app/seller-lead-query/mine' "$TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner inbox after Pause failed: $status" >&2; exit 1; }
python3 - "$RESPONSE" "$LEAD_ID" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data=json.load(handle)
if not any(str(item.get("id","")).lower()==sys.argv[2].lower() and item.get("contactedAtUtc") for item in data): raise SystemExit(f"Historical Lead disappeared: {data}")
PY
echo "SELLER_LEADS_HISTORY_PRESERVED: PASS"

echo "SELLER LEADS HTTP: PASSED"
