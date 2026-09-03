#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WINDOW = 100


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def classify_path(path: str) -> str:
    if path.startswith("public-web/"):
        return "frontend"
    if path.startswith(("main/", "modules/", "tests/")):
        return "backend"
    return "shared"


def changed_paths(commit: str) -> list[str]:
    parents = git("rev-list", "--parents", "-n", "1", commit).split()
    if len(parents) > 1:
        out = git("diff", "--name-only", parents[1], commit)
    else:
        out = git("show", "--pretty=", "--name-only", commit)
    return [line for line in out.splitlines() if line]


def workflow_paths(text: str) -> list[str] | None:
    lines = text.splitlines()
    in_pr = False
    pr_indent = None
    in_paths = False
    paths_indent = None
    values: list[str] = []
    found_pr = False
    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        stripped = raw.strip()
        if stripped == "pull_request:":
            in_pr = True
            found_pr = True
            pr_indent = indent
            in_paths = False
            continue
        if in_pr and pr_indent is not None and indent <= pr_indent and not stripped.startswith("#"):
            in_pr = False
            in_paths = False
        if not in_pr:
            continue
        if stripped == "paths:":
            in_paths = True
            paths_indent = indent
            continue
        if in_paths and paths_indent is not None:
            if indent <= paths_indent:
                in_paths = False
                continue
            match = re.match(r"-\s+['\"]?(.+?)['\"]?$", stripped)
            if match:
                values.append(match.group(1))
    if not found_pr:
        return None
    return values


def direct_cross_boundary_references() -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    frontend_ext = {".ts", ".tsx", ".js", ".jsx", ".json", ".mjs", ".cjs"}
    backend_ext = {".cs", ".csproj", ".props", ".targets", ".json", ".sh"}

    for path in (ROOT / "public-web").rglob("*"):
        if not path.is_file() or path.suffix not in frontend_ext or ".next" in path.parts or "node_modules" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in ("../main/", "../../main/", "../modules/", "../../modules/"):
            if pattern in text:
                findings.append({"file": str(path.relative_to(ROOT)), "reference": pattern, "direction": "frontend_to_backend"})

    for base in ("main", "modules", "tests"):
        for path in (ROOT / base).rglob("*"):
            if not path.is_file() or path.suffix not in backend_ext:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            if "public-web/" in text or "../public-web" in text:
                findings.append({"file": str(path.relative_to(ROOT)), "reference": "public-web", "direction": "backend_to_frontend"})
    return findings


def main() -> None:
    commits = git("rev-list", "--first-parent", f"--max-count={WINDOW}", "HEAD").splitlines()
    rows = []
    counts = {"backend_only": 0, "frontend_only": 0, "cross_boundary": 0}

    for commit in commits:
        paths = changed_paths(commit)
        classes = {classify_path(path) for path in paths}
        has_backend = "backend" in classes
        has_frontend = "frontend" in classes
        if not (has_backend or has_frontend):
            continue
        if has_backend and has_frontend:
            kind = "cross_boundary"
        elif has_backend:
            kind = "backend_only"
        else:
            kind = "frontend_only"
        counts[kind] += 1
        rows.append({"commit": commit, "classification": kind, "paths": paths})

    product_n = sum(counts.values())
    proportions = {key: (value / product_n if product_n else 0.0) for key, value in counts.items()}

    workflows = []
    no_path_filter = []
    frontend_scoped = 0
    backend_scoped = 0
    dual_scoped = 0
    for path in sorted((ROOT / ".github" / "workflows").glob("*.yml")):
        text = path.read_text(encoding="utf-8")
        paths = workflow_paths(text)
        if paths is None:
            continue
        frontend = any(p.startswith("public-web/") for p in paths)
        backend = any(p.startswith("main/") or p.startswith("modules/") for p in paths)
        if frontend:
            frontend_scoped += 1
        if backend:
            backend_scoped += 1
        if frontend and backend:
            dual_scoped += 1
        if not paths:
            no_path_filter.append(path.name)
        workflows.append({"workflow": path.name, "paths": paths, "frontend": frontend, "backend": backend})

    refs = direct_cross_boundary_references()
    result = {
        "protocol": {
            "commit_window": WINDOW,
            "history": "first-parent",
            "docs_only_excluded_from_product_commit_denominator": True,
        },
        "head": git("rev-parse", "HEAD"),
        "commits_examined_n": len(commits),
        "product_commits_n": product_n,
        "backend_only_n": counts["backend_only"],
        "frontend_only_n": counts["frontend_only"],
        "cross_boundary_n": counts["cross_boundary"],
        "backend_only_ratio": proportions["backend_only"],
        "frontend_only_ratio": proportions["frontend_only"],
        "cross_boundary_ratio": proportions["cross_boundary"],
        "direct_cross_boundary_reference_count": len(refs),
        "direct_cross_boundary_references": refs,
        "pr_workflows_n": len(workflows),
        "frontend_scoped_workflows_n": frontend_scoped,
        "backend_scoped_workflows_n": backend_scoped,
        "dual_scoped_workflows_n": dual_scoped,
        "pr_workflows_without_paths": no_path_filter,
        "commit_classifications": rows,
        "workflow_classifications": workflows,
    }
    output = ROOT / "artifacts" / "monorepo-coupling-baseline.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in result.items() if key not in {"commit_classifications", "workflow_classifications", "direct_cross_boundary_references"}}, indent=2))
    print(f"MONOREPO_COUPLING_BASELINE={output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
