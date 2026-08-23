#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5091}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-listing-http-lifecycle.log"
SWAGGER="${TMPDIR:-/tmp}/bpt2-listing-http-swagger.json"
ROUTES="${TMPDIR:-/tmp}/bpt2-listing-http-routes.env"
RESPONSE="${TMPDIR:-/tmp}/bpt2-listing-http-response.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$SWAGGER" ]] || { cat "$LOG" >&2; echo "Swagger did not become available." >&2; exit 1; }

python3 - "$SWAGGER" "$ROUTES" <<'PY'
import json
import re
import shlex
import sys

swagger_path, env_path = sys.argv[1:]
with open(swagger_path, encoding="utf-8") as handle:
    document = json.load(handle)
paths = document.get("paths", {})

def pick(fragment: str, verb: str, action: str | None = None, no_path_parameter: bool = False):
    candidates = []
    for path, operations in paths.items():
        operation = operations.get(verb.lower())
        if operation is None or fragment not in path:
            continue
        if no_path_parameter and "{" in path:
            continue
        haystack = f"{path} {operation.get('operationId', '')}".lower()
        if action and action.lower() not in haystack:
            continue
        candidates.append((path, operation))
    if not candidates:
        raise SystemExit(f"Missing {verb.upper()} operation for fragment={fragment!r}, action={action!r}")
    return sorted(candidates, key=lambda item: (item[0].count("{"), len(item[0]), item[0]))[0]

def route(path: str, operation: dict) -> tuple[str, str]:
    path_names = re.findall(r"\{([^}]+)\}", path)
    rendered = path
    for name in path_names:
        rendered = rendered.replace("{" + name + "}", "__ID__")
    query_name = ""
    if not path_names:
        for parameter in operation.get("parameters", []):
            if parameter.get("in") == "query" and parameter.get("name", "").lower() in {"id", "listingid"}:
                query_name = parameter["name"]
                break
    return rendered, query_name

create_path, _ = pick("listing-command", "post", no_path_parameter=True)
update_path, update_op = pick("listing-command", "put")
publish_path, publish_op = pick("listing-command", "post", action="publish")
public_list_path, _ = pick("public-listing", "get", no_path_parameter=True)
seller_upsert_path, _ = pick("seller-profile", "post", action="upsert", no_path_parameter=True)
identity_create = "/api/identity/users"

update_path, update_query = route(update_path, update_op)
publish_path, publish_query = route(publish_path, publish_op)

values = {
    "LISTING_CREATE": create_path,
    "LISTING_UPDATE": update_path,
    "LISTING_UPDATE_QUERY": update_query,
    "LISTING_PUBLISH": publish_path,
    "LISTING_PUBLISH_QUERY": publish_query,
    "PUBLIC_LIST": public_list_path,
    "SELLER_UPSERT": seller_upsert_path,
    "IDENTITY_CREATE": identity_create,
}
with open(env_path, "w", encoding="utf-8") as handle:
    for key, value in values.items():
        handle.write(f"{key}={shlex.quote(value)}\n")
print("LISTING HTTP ROUTES:", values)
PY

# shellcheck disable=SC1090
source "$ROUTES"

request() {
  local method="$1" url="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$url"
}

render_id_url() {
  local path="$1" query_name="$2" id="$3"
  local rendered="${path//__ID__/$id}"
  if [[ -n "$query_name" ]]; then
    printf '%s%s?%s=%s' "$BASE" "$rendered" "$query_name" "$id"
  else
    printf '%s%s' "$BASE" "$rendered"
  fi
}

get_token() {
  local username="$1"
  local password="$2"
  local token_file="${TMPDIR:-/tmp}/bpt2-token-${username}.json"
  local status
  status="$(curl --silent --show-error \
    --output "$token_file" \
    --write-out '%{http_code}' \
    -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  if [[ "$status" != "200" ]]; then
    echo "Token request for $username expected 200, got $status: $(cat "$token_file")" >&2
    return 1
  fi
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
value = data.get("access_token")
if not value:
    raise SystemExit(f"Token response did not contain access_token: {data}")
print(value)
PY
}

contains_listing() {
  local file="$1" listing_id="$2" expected="$3"
  python3 - "$file" "$listing_id" "$expected" <<'PY'
import json, sys
path, target, expected = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

def walk(value):
    if isinstance(value, dict):
        if str(value.get("id", "")).lower() == target.lower():
            return True
        return any(walk(item) for item in value.values())
    if isinstance(value, list):
        return any(walk(item) for item in value)
    return False

actual = walk(data)
want = expected == "true"
if actual != want:
    raise SystemExit(f"Listing visibility mismatch: expected contains={want}, actual={actual}, body={data}")
PY
}

assert_listing_whatsapp() {
  local file="$1" listing_id="$2" expected="$3"
  python3 - "$file" "$listing_id" "$expected" <<'PY'
import json, sys
path, target, expected = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

def find_listing(value):
    if isinstance(value, dict):
        if str(value.get("id", "")).lower() == target.lower():
            return value
        for item in value.values():
            found = find_listing(item)
            if found is not None:
                return found
    elif isinstance(value, list):
        for item in value:
            found = find_listing(item)
            if found is not None:
                return found
    return None

listing = find_listing(data)
if listing is None:
    raise SystemExit(f"Published Listing {target} not found in public response: {data}")
seller = listing.get("seller")
if not isinstance(seller, dict):
    raise SystemExit(f"Published Listing seller projection missing: {listing}")
actual = seller.get("whatsAppNumber")
if actual != expected:
    raise SystemExit(f"Public WhatsApp expected {expected!r}, got {actual!r}: {listing}")
PY
}

ADMIN_TOKEN="$(get_token admin '1q2w3E*')"
SELLER_B_USER="sellerb-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:12])
PY
)"
SELLER_B_PASSWORD='Bpt2-SellerB-9!x'
SELLER_B_EMAIL="${SELLER_B_USER}@example.invalid"
SELLER_B_BODY="$(python3 - "$SELLER_B_USER" "$SELLER_B_EMAIL" "$SELLER_B_PASSWORD" <<'PY'
import json, sys
username, email, password = sys.argv[1:]
print(json.dumps({
    "userName": username,
    "name": "Seller",
    "surname": "B",
    "email": email,
    "password": password,
    "isActive": True,
    "lockoutEnabled": True,
    "roleNames": []
}))
PY
)"
status="$(request POST "$BASE$IDENTITY_CREATE" "$ADMIN_TOKEN" "$SELLER_B_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Identity user create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
SELLER_B_TOKEN="$(get_token "$SELLER_B_USER" "$SELLER_B_PASSWORD")"

echo "HTTP_AUTH_USERS: PASS"

EXPECTED_WHATSAPP="5511999998877"
SELLER_PROFILE_BODY='{"displayName":"BPT Admin Seller","whatsAppNumber":"+55 (11) 99999-8877"}'
status="$(request POST "$BASE$SELLER_UPSERT" "$ADMIN_TOKEN" "$SELLER_PROFILE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile upsert expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
ACTUAL_WHATSAPP="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["whatsAppNumber"])
PY
)"
[[ "$ACTUAL_WHATSAPP" == "$EXPECTED_WHATSAPP" ]] || { echo "Seller WhatsApp normalization expected $EXPECTED_WHATSAPP, got $ACTUAL_WHATSAPP" >&2; exit 1; }
echo "HTTP_SELLER_CONTACT_NORMALIZED: PASS"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": "HTTP Lifecycle Listing",
    "price": 120000,
    "description": "Listing created by the real authenticated HTTP API.",
    "manufactureYear": 2024,
    "mileageKm": 9000,
    "color": "Prata",
    "city": "Porto Alegre",
    "stateCode": "RS"
}))
PY
)"
status="$(request POST "$BASE$LISTING_CREATE" "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
read -r LISTING_ID CREATE_STAMP CREATE_STATUS < <(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
print(data["id"], data["concurrencyStamp"], data["status"])
PY
)
[[ "$CREATE_STATUS" == "Draft" ]] || { echo "New Listing must be Draft, got $CREATE_STATUS" >&2; exit 1; }
[[ -n "$CREATE_STAMP" ]] || { echo "Create Listing returned empty concurrency stamp" >&2; exit 1; }
echo "HTTP_CREATE_DRAFT: PASS"

status="$(request GET "$BASE$PUBLIC_LIST")"
[[ "$status" == "200" ]] || { echo "Public list expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
contains_listing "$RESPONSE" "$LISTING_ID" false
echo "HTTP_DRAFT_PRIVATE: PASS"

PUBLISH_URL="$(render_id_url "$LISTING_PUBLISH" "$LISTING_PUBLISH_QUERY" "$LISTING_ID")"
status="$(request POST "$PUBLISH_URL" "$SELLER_B_TOKEN")"
[[ "$status" == "403" ]] || { echo "Cross-seller publish expected 403, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "HTTP_OWNERSHIP: PASS"

status="$(request POST "$PUBLISH_URL" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner publish expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
PUBLISH_STAMP="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["concurrencyStamp"])
PY
)"
[[ -n "$PUBLISH_STAMP" ]] || { echo "Publish returned empty concurrency stamp" >&2; exit 1; }

status="$(request GET "$BASE$PUBLIC_LIST")"
[[ "$status" == "200" ]] || { echo "Public list expected 200 after publish, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
contains_listing "$RESPONSE" "$LISTING_ID" true
assert_listing_whatsapp "$RESPONSE" "$LISTING_ID" "$EXPECTED_WHATSAPP"
echo "HTTP_PUBLISH_PUBLIC: PASS"
echo "HTTP_PUBLIC_SELLER_CONTACT: PASS"

UPDATE_URL="$(render_id_url "$LISTING_UPDATE" "$LISTING_UPDATE_QUERY" "$LISTING_ID")"
UPDATE_BODY="$(python3 - "$PUBLISH_STAMP" <<'PY'
import json, sys
print(json.dumps({"title": "HTTP Lifecycle Listing Updated", "price": 121000, "concurrencyStamp": sys.argv[1]}))
PY
)"
status="$(request PUT "$UPDATE_URL" "$ADMIN_TOKEN" "$UPDATE_BODY")"
[[ "$status" == "200" ]] || { echo "Owner update expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
UPDATED_STAMP="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["concurrencyStamp"])
PY
)"
[[ "$UPDATED_STAMP" != "$PUBLISH_STAMP" ]] || { echo "Successful update did not rotate concurrency stamp" >&2; exit 1; }

STALE_BODY="$(python3 - "$PUBLISH_STAMP" <<'PY'
import json, sys
print(json.dumps({"title": "HTTP Lifecycle Stale Update", "price": 122000, "concurrencyStamp": sys.argv[1]}))
PY
)"
status="$(request PUT "$UPDATE_URL" "$ADMIN_TOKEN" "$STALE_BODY")"
[[ "$status" == "409" ]] || { echo "Stale update expected 409, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "HTTP_CONCURRENCY: PASS"

echo "LISTING HTTP LIFECYCLE: PASSED"
