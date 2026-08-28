#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path

CHECKER = Path(__file__).with_name("check-harness.py")
spec = importlib.util.spec_from_file_location("check_harness", CHECKER)
if spec is None or spec.loader is None:
    raise RuntimeError("unable to load check-harness.py")
check_harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check_harness)


def main() -> int:
    tracked = [
        "main/BomPraTi/Migrations/20260823012701_Initial.cs",
        "modules/catalog/src/BomPraTi.Catalog/Data/CatalogDbContext.cs",
        "modules/catalog/src/BomPraTi.Catalog/Data/Migrations/Gate/20260828_GateInitialCatalog.cs",
        "modules/marketplace/src/BomPraTi.Marketplace/Data/Migrations/Gate/MarketplaceDbContextModelSnapshot.cs",
        "docs/audits/2026-08-28-ci-smoke-and-migration-authority.md",
    ]

    forbidden = check_harness.ephemeral_migration_output_paths(tracked)
    assert forbidden == [
        "modules/catalog/src/BomPraTi.Catalog/Data/Migrations/Gate/20260828_GateInitialCatalog.cs",
        "modules/marketplace/src/BomPraTi.Marketplace/Data/Migrations/Gate/MarketplaceDbContextModelSnapshot.cs",
    ], forbidden

    allowed = check_harness.ephemeral_migration_output_paths([
        "main/BomPraTi/Migrations/20260823012701_Initial.cs",
        "modules/catalog/src/BomPraTi.Catalog/Data/CatalogDbContext.cs",
    ])
    assert allowed == [], allowed

    print("EPHEMERAL MIGRATION AUTHORITY CHECK: PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
