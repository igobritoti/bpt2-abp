#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULES = ROOT / "modules"
violations: list[str] = []

ALLOWED_PROJECT_REFS: dict[str, set[str]] = {
    "BomPraTi.Catalog.Contracts": set(),
    "BomPraTi.Catalog": {"BomPraTi.Catalog.Contracts"},
    "BomPraTi.Media.Contracts": set(),
    "BomPraTi.Media": {"BomPraTi.Media.Contracts"},
    "BomPraTi.Sellers.Contracts": set(),
    "BomPraTi.Sellers": {"BomPraTi.Sellers.Contracts"},
    "BomPraTi.Marketplace.Contracts": set(),
    "BomPraTi.Marketplace": {
        "BomPraTi.Marketplace.Contracts",
        "BomPraTi.Catalog.Contracts",
        "BomPraTi.Media.Contracts",
        "BomPraTi.Sellers.Contracts",
    },
    "BomPraTi.Ingestion.Contracts": set(),
    "BomPraTi.Ingestion": {
        "BomPraTi.Ingestion.Contracts",
        "BomPraTi.Catalog.Contracts",
    },
}

MODULE_BY_KEY = {
    "catalog": "Catalog",
    "media": "Media",
    "sellers": "Sellers",
    "marketplace": "Marketplace",
    "ingestion": "Ingestion",
}

FORBIDDEN_CONTRACT_PACKAGE_PREFIXES = (
    "Microsoft.EntityFrameworkCore",
    "Npgsql",
    "Volo.Abp.EntityFrameworkCore",
)


def parse_project(csproj: pathlib.Path) -> ET.ElementTree | None:
    try:
        return ET.parse(csproj)
    except ET.ParseError as exc:
        violations.append(f"{csproj.relative_to(ROOT)}: invalid XML: {exc}")
        return None


for csproj in MODULES.rglob("*.csproj"):
    assembly = csproj.stem
    tree = parse_project(csproj)
    if tree is None:
        continue

    if assembly not in ALLOWED_PROJECT_REFS:
        violations.append(f"{csproj.relative_to(ROOT)}: unknown BPT module assembly '{assembly}'")
        continue

    allowed = ALLOWED_PROJECT_REFS[assembly]
    for ref in tree.findall(".//ProjectReference"):
        include = ref.attrib.get("Include", "").replace("\\", "/")
        target = pathlib.Path(include).stem
        if target.startswith("BomPraTi.") and target not in allowed:
            violations.append(
                f"{csproj.relative_to(ROOT)}: project reference '{assembly}' -> '{target}' is not allowed; "
                f"allowed BPT refs: {sorted(allowed) or 'none'}"
            )

    if assembly.endswith(".Contracts"):
        for package in tree.findall(".//PackageReference"):
            name = package.attrib.get("Include", "")
            if name.startswith(FORBIDDEN_CONTRACT_PACKAGE_PREFIXES):
                violations.append(
                    f"{csproj.relative_to(ROOT)}: Contracts assembly depends on infrastructure package '{name}'"
                )


qualified_re = re.compile(r"\bBomPraTi\.(Catalog|Media|Sellers|Marketplace|Ingestion)(\.[A-Za-z_][A-Za-z0-9_.]*)?")
for source in MODULES.rglob("*.cs"):
    rel = source.relative_to(MODULES)
    own_module = MODULE_BY_KEY.get(rel.parts[0])
    if not own_module:
        continue

    try:
        src_idx = rel.parts.index("src")
        assembly = rel.parts[src_idx + 1]
    except (ValueError, IndexError):
        violations.append(f"{source.relative_to(ROOT)}: source is outside expected module src layout")
        continue

    allowed_assemblies = ALLOWED_PROJECT_REFS.get(assembly, set())
    text = source.read_text(encoding="utf-8")
    for target, suffix in qualified_re.findall(text):
        if target == own_module:
            continue

        target_contract = f"BomPraTi.{target}.Contracts"
        suffix = suffix or ""
        if not suffix.startswith(".Contracts") or target_contract not in allowed_assemblies:
            violations.append(
                f"{source.relative_to(ROOT)}: cross-module source reference 'BomPraTi.{target}{suffix}' is forbidden; "
                f"use an explicitly allowed Contracts dependency"
            )


visibility = MODULES / "marketplace/src/BomPraTi.Marketplace/Domain/ListingVisibility.cs"
if not visibility.exists() or "ListingStatus.Published" not in visibility.read_text(encoding="utf-8"):
    violations.append("Marketplace public visibility invariant is missing Published-only anchor")

marketplace = MODULES / "marketplace"
for source in marketplace.rglob("*.cs"):
    if "Data" in source.parts and "Migrations" in source.parts:
        continue
    if "StorageKey" in source.read_text(encoding="utf-8"):
        violations.append(
            f"{source.relative_to(ROOT)}: Marketplace must reference MediaAssetId, never a storage-provider key"
        )

for key, module in MODULE_BY_KEY.items():
    impl = MODULES / key / "src" / f"BomPraTi.{module}"
    contexts = list(impl.rglob("*DbContext.cs"))
    if len(contexts) != 1:
        violations.append(
            f"modules/{key}: expected exactly one implementation DbContext, found {len(contexts)}"
        )
    contracts = MODULES / key / "src" / f"BomPraTi.{module}.Contracts"
    if list(contracts.rglob("*DbContext.cs")):
        violations.append(f"modules/{key}: Contracts assembly must not contain a DbContext")


if violations:
    print("ARCHITECTURE BOUNDARY CHECK: FAILED")
    for violation in violations:
        print(f" - {violation}")
    sys.exit(1)

print("ARCHITECTURE BOUNDARY CHECK: PASSED")
