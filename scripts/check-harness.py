#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from datetime import date, datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "AGENTS.md",
    "ARCHITECTURE.md",
    "docs/README.md",
    "docs/LOCAL-DEVELOPMENT.md",
    "docs/agent/CURRENT-WORK.md",
    "docs/PRODUCT.md",
    "docs/MDV.md",
    "docs/ENGINEERING.md",
    "docs/QUALITY.md",
    "docs/SECURITY.md",
    "docs/PLANS.md",
    "docs/exec-plans/tech-debt-tracker.md",
    "docs/exec-plans/completed/README.md",
    "docs/references/OPENAI_ENGINEERING_GUIDANCE.md",
    "docs/generated/repository-facts.md",
    "scripts/generate-repo-facts.py",
]

REQUIRED_DIRS = [
    "docs/agent",
    "docs/adr",
    "docs/exec-plans/active",
    "docs/exec-plans/completed",
    "docs/generated",
    "docs/references",
]

ALLOWED_AGENTS_H2 = {"Start here", "Canonical sources", "Execution"}
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
DATE_FIELD = re.compile(r"^(Last verified|Reviewed):\s+\*\*(\d{4}-\d{2}-\d{2})\*\*\s*$", re.MULTILINE)


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def check_required(errors: list[str]) -> None:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).is_file():
            fail(errors, f"missing required file: {relative}")
    for relative in REQUIRED_DIRS:
        if not (ROOT / relative).is_dir():
            fail(errors, f"missing required directory: {relative}")


def check_agents(errors: list[str]) -> None:
    path = ROOT / "AGENTS.md"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if len(lines) > 80:
        fail(errors, f"AGENTS.md has {len(lines)} lines; maximum is 80")
    if len(text.encode("utf-8")) > 8192:
        fail(errors, "AGENTS.md exceeds 8 KiB; move detail to docs/")
    headings = {line[3:].strip() for line in lines if line.startswith("## ")}
    unexpected = headings - ALLOWED_AGENTS_H2
    if unexpected:
        fail(errors, f"AGENTS.md contains non-map sections: {sorted(unexpected)}")
    required_refs = {
        "docs/agent/CURRENT-WORK.md",
        "docs/README.md",
        "docs/ENGINEERING.md",
        "docs/QUALITY.md",
    }
    for ref in required_refs:
        if ref not in text:
            fail(errors, f"AGENTS.md must point to {ref}")


def local_markdown_files() -> list[Path]:
    files = [ROOT / "AGENTS.md", ROOT / "ARCHITECTURE.md", ROOT / "README.md"]
    files.extend((ROOT / "docs").rglob("*.md"))
    return sorted(path for path in files if path.is_file())


def check_links(errors: list[str]) -> None:
    for path in local_markdown_files():
        text = path.read_text(encoding="utf-8")
        for raw in MARKDOWN_LINK.findall(text):
            target = raw.strip().split(maxsplit=1)[0].strip("<>")
            if not target or target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            target = target.split("#", 1)[0]
            resolved = (path.parent / target).resolve()
            try:
                resolved.relative_to(ROOT.resolve())
            except ValueError:
                fail(errors, f"{path.relative_to(ROOT)} links outside repository: {raw}")
                continue
            if not resolved.exists():
                fail(errors, f"broken local link in {path.relative_to(ROOT)}: {raw}")


def parse_date_field(path: Path, field: str, errors: list[str]):
    text = path.read_text(encoding="utf-8")
    for name, value in DATE_FIELD.findall(text):
        if name == field:
            try:
                return datetime.strptime(value, "%Y-%m-%d").date()
            except ValueError:
                fail(errors, f"invalid {field} date in {path.relative_to(ROOT)}: {value}")
                return None
    fail(errors, f"missing '{field}: **YYYY-MM-DD**' in {path.relative_to(ROOT)}")
    return None


def check_freshness(errors: list[str]) -> None:
    today = datetime.now(timezone.utc).date()
    checks = [
        (ROOT / "docs/agent/CURRENT-WORK.md", "Last verified", 45),
        (ROOT / "docs/references/OPENAI_ENGINEERING_GUIDANCE.md", "Reviewed", 180),
    ]
    for path, field, max_age in checks:
        if not path.exists():
            continue
        value = parse_date_field(path, field, errors)
        if value is None:
            continue
        age = (today - value).days
        if age < 0:
            fail(errors, f"{path.relative_to(ROOT)} has future {field} date: {value}")
        elif age > max_age:
            fail(errors, f"{path.relative_to(ROOT)} is stale ({age} days; max {max_age})")


def check_current_work(errors: list[str]) -> None:
    path = ROOT / "docs/agent/CURRENT-WORK.md"
    if not path.exists():
        return
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) > 120:
        fail(errors, f"CURRENT-WORK.md has {len(lines)} lines; keep current state short")
    forbidden = {"## Histórico", "## History", "## Changelog"}
    found = {line.strip() for line in lines} & forbidden
    if found:
        fail(errors, f"CURRENT-WORK.md must not accumulate history: {sorted(found)}")


def check_plans(errors: list[str]) -> None:
    active_dir = ROOT / "docs/exec-plans/active"
    if not active_dir.exists():
        return
    required_sections = {"## Objetivo", "## Critérios de aceite", "## Progress log", "## Decision log"}
    for path in sorted(active_dir.glob("*.md")):
        if path.name.lower() == "readme.md":
            continue
        text = path.read_text(encoding="utf-8")
        if "Status: **ATIVO**" not in text:
            fail(errors, f"active plan is not marked ATIVO: {path.relative_to(ROOT)}")
        missing = [section for section in required_sections if section not in text]
        if missing:
            fail(errors, f"active plan missing sections {missing}: {path.relative_to(ROOT)}")


def check_generated(errors: list[str]) -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts/generate-repo-facts.py"), "--check"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        detail = (result.stdout + result.stderr).strip()
        fail(errors, f"generated facts check failed: {detail}")


def main() -> int:
    errors: list[str] = []
    check_required(errors)
    check_agents(errors)
    check_links(errors)
    check_freshness(errors)
    check_current_work(errors)
    check_plans(errors)
    check_generated(errors)

    if errors:
        print("HARNESS CHECK: FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("HARNESS CHECK: PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())