#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_CANONICAL_VEHICLE_API_PORT:-5107}"
API_BASE="http://127.0.0.1:${API_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-canonical-vehicle-search"
API_LOG="$TMP/api.log"
RESPONSE="$TMP/response.json"

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

curl --fail --silent --show-error \
  "$API_BASE/api/app/vehicle-catalog/$BPT_FIXTURE_VEHICLE_ID" \
  -o "$RESPONSE"
IFS=$'\t' read -r BRAND MODEL GENERATION VERSION < <(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    item = json.load(handle)
print(f"{item['brand']}\t{item['model']}\t{item.get('generation') or ''}\t{item['version']}")
PY
)

assert_query_finds_fixture() {
  local label="$1" query="$2"
  [[ -n "$query" ]] || { echo "$label fixture value is empty" >&2; exit 1; }
  curl --fail --silent --show-error --get "$API_BASE/api/app/vehicle-catalog" \
    --data-urlencode "query=$query" \
    --data-urlencode 'take=12' \
    -o "$RESPONSE"
  python3 - "$RESPONSE" "$BPT_FIXTURE_VEHICLE_ID" "$label" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    items = json.load(handle)
expected = sys.argv[2].lower()
if not isinstance(items, list):
    raise SystemExit(f"{sys.argv[3]} query did not return a list: {items!r}")
ids = {str(item.get("id", "")).lower() for item in items}
if expected not in ids:
    raise SystemExit(f"{sys.argv[3]} query missing fixture {expected}: {ids}")
PY
  echo "PUBLIC_CANONICAL_VEHICLE_QUERY_${label}: PASS"
}

assert_query_finds_fixture BRAND "${BRAND,,}"
assert_query_finds_fixture MODEL "$MODEL"
assert_query_finds_fixture GENERATION "$GENERATION"
assert_query_finds_fixture VERSION "$VERSION"

curl --fail --silent --show-error --get "$API_BASE/api/app/vehicle-catalog" \
  --data-urlencode 'query=__bpt_no_canonical_vehicle__' \
  --data-urlencode 'take=12' \
  -o "$RESPONSE"
python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    items = json.load(handle)
if items != []:
    raise SystemExit(f"Unknown canonical query must be empty: {items!r}")
PY
echo "PUBLIC_CANONICAL_VEHICLE_QUERY_EMPTY: PASS"

echo "PUBLIC CANONICAL VEHICLE SEARCH HTTP: PASSED"
