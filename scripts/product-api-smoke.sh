#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5088}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-product-api.log"
SWAGGER="${TMPDIR:-/tmp}/bpt2-swagger.json"
PATHS_ENV="${TMPDIR:-/tmp}/bpt2-api-paths.env"
PUBLIC_RESPONSE="${TMPDIR:-/tmp}/bpt2-public-list-response.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"

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

if [[ ! -s "$SWAGGER" ]]; then
  cat "$LOG" >&2
  echo "Swagger did not become available." >&2
  exit 1
fi

python3 - "$SWAGGER" "$PATHS_ENV" <<'PY'
import json
import shlex
import sys

swagger_path, env_path = sys.argv[1:]
with open(swagger_path, encoding="utf-8") as handle:
    document = json.load(handle)
paths = document.get("paths", {})

def pick(fragment: str, verb: str, *, no_path_parameter: bool = False) -> str:
    candidates = []
    for path, operations in paths.items():
        if fragment in path and verb.lower() in operations:
            if no_path_parameter and "{" in path:
                continue
            candidates.append(path)
    if not candidates:
        raise SystemExit(f"Missing {verb.upper()} API surface containing {fragment!r}. Available: {sorted(paths)}")
    return sorted(candidates, key=lambda value: (value.count("{"), len(value), value))[0]

def pick_public_detail() -> str:
    candidates = [
        path
        for path, operations in paths.items()
        if "public-listing" in path and "get" in operations and path.count("{") == 1
    ]
    if not candidates:
        raise SystemExit(f"Missing public Listing detail GET. Available: {sorted(paths)}")
    return sorted(candidates, key=lambda value: (len(value), value))[0]

selected = {
    "SELLER_GET": pick("seller-profile", "get"),
    "LISTING_CREATE": pick("listing-command", "post", no_path_parameter=True),
    "CATALOG_LIST": pick("vehicle-catalog", "get", no_path_parameter=True),
    "PUBLIC_LIST": pick("public-listing", "get", no_path_parameter=True),
    "PUBLIC_DETAIL": pick_public_detail(),
}

schemas = document.get("components", {}).get("schemas", {})
public_listing_schema = next(
    (schema for name, schema in schemas.items() if name.split(".")[-1] == "PublicListingDto"),
    None,
)
if public_listing_schema is None:
    raise SystemExit(f"PublicListingDto schema missing from Swagger components: {sorted(schemas)}")
properties = {name.lower() for name in public_listing_schema.get("properties", {})}
missing = {"seller", "vehicle", "photos"} - properties
if missing:
    raise SystemExit(f"PublicListingDto missing detail facts {sorted(missing)}: {sorted(properties)}")

public_seller_schema = next(
    (schema for name, schema in schemas.items() if name.split(".")[-1] == "PublicListingSellerDto"),
    None,
)
if public_seller_schema is None:
    raise SystemExit(f"PublicListingSellerDto schema missing from Swagger components: {sorted(schemas)}")
seller_properties = {name.lower() for name in public_seller_schema.get("properties", {})}
if "whatsappnumber" not in seller_properties:
    raise SystemExit(f"PublicListingSellerDto missing WhatsAppNumber: {sorted(seller_properties)}")

with open(env_path, "w", encoding="utf-8") as handle:
    for key, value in selected.items():
        handle.write(f"{key}={shlex.quote(value)}\n")
print("PRODUCT API SURFACES:", selected)
print("PUBLIC LISTING DETAIL CONTRACT: seller + vehicle + photos")
print("PUBLIC LISTING SELLER CONTRACT: whatsappNumber")
PY

# shellcheck disable=SC1090
source "$PATHS_ENV"

status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$BASE$SELLER_GET")"
[[ "$status" == "401" ]] || { echo "Expected anonymous Seller API to return 401, got $status" >&2; exit 1; }

status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  -H 'Content-Type: application/json' -d '{}' "$BASE$LISTING_CREATE")"
[[ "$status" == "401" ]] || { echo "Expected anonymous Listing command to return 401, got $status" >&2; exit 1; }

status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$BASE$CATALOG_LIST")"
[[ "$status" == "200" ]] || { echo "Expected anonymous Catalog list to return 200, got $status" >&2; exit 1; }

status="$(curl --silent --show-error --output "$PUBLIC_RESPONSE" --write-out '%{http_code}' "$BASE$PUBLIC_LIST")"
[[ "$status" == "200" ]] || { echo "Expected anonymous public Listing list to return 200, got $status" >&2; exit 1; }
python3 - "$PUBLIC_RESPONSE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if not isinstance(data, dict):
    raise SystemExit(f"Public Listing list must return a paged object, got: {data!r}")
if data.get("totalCount") != 0:
    raise SystemExit(f"Fresh public Listing totalCount expected 0, got: {data!r}")
if data.get("items") != []:
    raise SystemExit(f"Fresh public Listing items expected [], got: {data!r}")
PY

echo "PUBLIC_LIST_DETAIL_CONTRACT: PASS"
echo "PUBLIC_LIST_PAGING_CONTRACT: PASS"
echo "PUBLIC_LIST_CONTACT_CONTRACT: PASS"
echo "PRODUCT API SMOKE: PASSED"
