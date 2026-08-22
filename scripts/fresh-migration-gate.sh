#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="$ROOT/main/BomPraTi/BomPraTi.csproj"
CONNECTION="${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"

command -v dotnet >/dev/null || { echo "dotnet SDK is required." >&2; exit 2; }

dotnet tool restore

dotnet build "$HOST" --configuration Release --nologo

add_migration() {
  local project="$1" context="$2" name="$3"
  dotnet tool run dotnet-ef migrations add "$name" \
    --project "$project" \
    --startup-project "$HOST" \
    --context "$context" \
    --output-dir Data/Migrations/Gate \
    --no-build
}

update_context() {
  local project="$1" context="$2"
  dotnet tool run dotnet-ef database update \
    --project "$project" \
    --startup-project "$HOST" \
    --context "$context" \
    --connection "$CONNECTION" \
    --no-build
}

add_migration "$ROOT/modules/catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj" CatalogDbContext GateInitialCatalog
add_migration "$ROOT/modules/media/src/BomPraTi.Media/BomPraTi.Media.csproj" MediaDbContext GateInitialMedia
add_migration "$ROOT/modules/sellers/src/BomPraTi.Sellers/BomPraTi.Sellers.csproj" SellersDbContext GateInitialSellers
add_migration "$ROOT/modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj" MarketplaceDbContext GateInitialMarketplace
add_migration "$ROOT/modules/ingestion/src/BomPraTi.Ingestion/BomPraTi.Ingestion.csproj" IngestionDbContext GateInitialIngestion

update_context "$HOST" BomPraTiDbContext
update_context "$ROOT/modules/catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj" CatalogDbContext
update_context "$ROOT/modules/media/src/BomPraTi.Media/BomPraTi.Media.csproj" MediaDbContext
update_context "$ROOT/modules/sellers/src/BomPraTi.Sellers/BomPraTi.Sellers.csproj" SellersDbContext
update_context "$ROOT/modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj" MarketplaceDbContext
update_context "$ROOT/modules/ingestion/src/BomPraTi.Ingestion/BomPraTi.Ingestion.csproj" IngestionDbContext

echo "FRESH MIGRATION GATE: PASSED"
