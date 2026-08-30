#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
USES_RE = re.compile(r"^\s*(?:-\s*)?uses:\s*['\"]?([^'\"#\s]+)")
FULL_SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")


def main() -> int:
    if not WORKFLOWS.is_dir():
        print("ACTION PINNING CHECK: FAILED")
        print("- missing .github/workflows directory")
        return 1

    refs: list[tuple[Path, int, str]] = []
    violations: list[tuple[Path, int, str, str]] = []

    workflow_files = sorted([*WORKFLOWS.glob("*.yml"), *WORKFLOWS.glob("*.yaml")])
    for path in workflow_files:
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            match = USES_RE.match(line)
            if not match:
                continue

            ref = match.group(1)
            refs.append((path, lineno, ref))

            if ref.startswith("./") or ref.startswith("docker://"):
                continue

            if "@" not in ref:
                violations.append((path, lineno, ref, "external action/reusable workflow has no @ref"))
                continue

            target, revision = ref.rsplit("@", 1)
            if "/" not in target:
                violations.append((path, lineno, ref, "unrecognized external uses reference"))
                continue

            if not FULL_SHA_RE.fullmatch(revision):
                violations.append((path, lineno, ref, "external uses reference is not pinned to a full 40-hex commit SHA"))

    external_count = sum(1 for _, _, ref in refs if not ref.startswith(("./", "docker://")))
    print(f"ACTION_PINNING_WORKFLOW_FILES: {len(workflow_files)}")
    print(f"ACTION_PINNING_USES_REFS: {len(refs)}")
    print(f"ACTION_PINNING_EXTERNAL_REFS: {external_count}")

    if violations:
        print("ACTION PINNING CHECK: FAILED")
        for path, lineno, ref, reason in violations:
            print(f"- {path.relative_to(ROOT)}:{lineno}: {ref}: {reason}")
        return 1

    print("ACTION PINNING CHECK: PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
