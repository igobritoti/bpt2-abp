#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="$ROOT/main/BomPraTi/BomPraTi.csproj"

command -v dotnet >/dev/null || { echo "dotnet SDK is required." >&2; exit 2; }
dotnet tool restore

CONNECTION_ARGS=()
if [[ -n "${BPT_DB_CONNECTION:-}" ]]; then
  CONNECTION_ARGS=(--connection "$BPT_DB_CONNECTION")
fi

update_context() {
  local project="$1" context="$2"
  dotnet tool run dotnet-ef database update \
    --project "$project" \
    --startup-project "$HOST" \
    --context "$context" \
    "${CONNECTION_ARGS[@]}"
}

update_context "$ROOT/modules/catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj" CatalogDbContext
update_context "$ROOT/modules/sellers/src/BomPraTi.Sellers/BomPraTi.Sellers.csproj" SellersDbContext
