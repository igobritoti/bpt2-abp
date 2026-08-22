#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "main"

MODULE_TYPES = [
    "BomPraTiCatalogModule",
    "BomPraTiMarketplaceModule",
    "BomPraTiIngestionModule",
]
MODULE_USINGS = [
    "using BomPraTi.Catalog;",
    "using BomPraTi.Ingestion;",
    "using BomPraTi.Marketplace;",
]


def patch_host_module(text: str) -> str:
    missing_usings = [u for u in MODULE_USINGS if u not in text]
    if missing_usings:
        text = "\n".join(missing_usings) + "\n" + text

    if not all(f"typeof({name})" in text for name in MODULE_TYPES):
        match = re.search(r"\[DependsOn\(\s*", text)
        if not match:
            raise ValueError("Could not locate [DependsOn( in BomPraTiModule.cs")
        insertion = "\n    " + ",\n    ".join(f"typeof({name})" for name in MODULE_TYPES) + ","
        text = text[: match.end()] + insertion + text[match.end() :]

    host_controller_line = "options.ConventionalControllers.Create(typeof(BomPraTiModule).Assembly);"
    if host_controller_line not in text:
        raise ValueError("Could not locate host ConventionalControllers registration")

    controller_lines = [
        f"options.ConventionalControllers.Create(typeof({name}).Assembly);"
        for name in MODULE_TYPES
    ]
    missing_controllers = [line for line in controller_lines if line not in text]
    if missing_controllers:
        indent = "            "
        replacement = host_controller_line + "\n" + "\n".join(indent + line for line in missing_controllers)
        text = text.replace(host_controller_line, replacement, 1)

    return text


def discover_host_artifacts(main_dir: pathlib.Path) -> tuple[pathlib.Path, pathlib.Path]:
    module_files = [p for p in main_dir.rglob("BomPraTiModule.cs") if "obj" not in p.parts]
    if len(module_files) != 1:
        raise ValueError(f"Expected exactly one BomPraTiModule.cs, found {len(module_files)}")

    module_file = module_files[0]
    host_projects = list(module_file.parent.glob("*.csproj"))
    if len(host_projects) != 1:
        raise ValueError(
            f"Expected exactly one host csproj beside {module_file.name}, found {len(host_projects)}"
        )

    return host_projects[0], module_file


def main() -> int:
    try:
        host, module_file = discover_host_artifacts(MAIN)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    module_projects = [
        ROOT / "modules/catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj",
        ROOT / "modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj",
        ROOT / "modules/ingestion/src/BomPraTi.Ingestion/BomPraTi.Ingestion.csproj",
    ]
    for project in module_projects:
        subprocess.run(["dotnet", "add", str(host), "reference", str(project)], check=True)

    try:
        patched = patch_host_module(module_file.read_text(encoding="utf-8-sig"))
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 3

    module_file.write_text(patched, encoding="utf-8")
    print(
        f"Wired module references, DependsOn entries and conventional API controllers into "
        f"{host.relative_to(ROOT)} and {module_file.relative_to(ROOT)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
