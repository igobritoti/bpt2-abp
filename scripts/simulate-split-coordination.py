#!/usr/bin/env python3
from __future__ import annotations

import fnmatch
import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WINDOW = 100


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def changed_paths(commit: str) -> list[str]:
    parents = git("rev-list", "--parents", "-n", "1", commit).split()
    if len(parents) > 1:
        out = git("diff", "--name-only", parents[1], commit)
    else:
        out = git("show", "--pretty=", "--name-only", commit)
    return [line for line in out.splitlines() if line]


def classify(path: str) -> str:
    if path.startswith("public-web/"):
        return "frontend"
    if path.startswith(("main/", "modules/", "tests/")):
        return "backend"
    return "shared"


def parse_pr_paths(text: str) -> list[str] | None:
    lines = text.splitlines()
    in_pr = False
    pr_indent: int | None = None
    in_paths = False
    paths_indent: int | None = None
    paths: list[str] = []
    found_pr = False
    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        stripped = raw.strip()
        if stripped == "pull_request:":
            found_pr = True
            in_pr = True
            pr_indent = indent
            in_paths = False
            continue
        if in_pr and pr_indent is not None and indent <= pr_indent:
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
                paths.append(match.group(1))
    if not found_pr:
        return None
    return paths


def workflow_definitions(ref: str) -> dict[str, list[str]]:
    names = git("ls-tree", "-r", "--name-only", ref, ".github/workflows").splitlines()
    result: dict[str, list[str]] = {}
    for name in names:
        if not name.endswith((".yml", ".yaml")):
            continue
        text = git("show", f"{ref}:{name}")
        paths = parse_pr_paths(text)
        if paths is not None:
            result[Path(name).name] = paths
    return result


def path_matches(path: str, pattern: str) -> bool:
    return fnmatch.fnmatchcase(path, pattern)


def workflow_matches(paths: list[str], patterns: list[str]) -> bool:
    if not patterns:
        return True
    selected = False
    for pattern in patterns:
        negative = pattern.startswith("!")
        actual = pattern[1:] if negative else pattern
        if any(path_matches(path, actual) for path in paths):
            selected = not negative
    return selected


def triggered(paths: list[str], workflows: dict[str, list[str]]) -> set[str]:
    return {name for name, patterns in workflows.items() if workflow_matches(paths, patterns)}


def is_backend_contract(path: str) -> bool:
    return ".Contracts/" in path or path.startswith("main/BomPraTi/Controllers/")


def is_frontend_client(path: str) -> bool:
    return path.startswith("public-web/lib/") or path.startswith("public-web/app/api/")


def main() -> None:
    history_ref = os.environ.get("BPT_SPLIT_HISTORY_REF", "53be795b6205ef57c03f1118e0c0287dc0f2873c")
    workflow_ref = os.environ.get("BPT_SPLIT_WORKFLOW_REF", "e0cb70b9307d0122541d1cf8a04686d9d044bad4")
    history_sha = git("rev-parse", history_ref)
    workflow_sha = git("rev-parse", workflow_ref)
    workflows = workflow_definitions(workflow_sha)

    cross_changes: list[tuple[str, list[str]]] = []
    for commit in git("rev-list", "--first-parent", f"--max-count={WINDOW}", history_sha).splitlines():
        paths = changed_paths(commit)
        kinds = {classify(path) for path in paths}
        if "backend" in kinds and "frontend" in kinds:
            cross_changes.append((commit, paths))

    rows = []
    full_invocations = 0
    split_invocations = 0
    duplicated_invocations = 0
    shared_paths_total = 0
    changes_with_shared = 0
    contract_sync_candidates = 0

    for commit, paths in cross_changes:
        backend = [p for p in paths if classify(p) == "backend"]
        frontend = [p for p in paths if classify(p) == "frontend"]
        shared = [p for p in paths if classify(p) == "shared"]
        full_wf = triggered(paths, workflows)
        backend_wf = triggered(backend, workflows)
        frontend_wf = triggered(frontend, workflows)
        duplicated = backend_wf & frontend_wf
        contract_sync = any(is_backend_contract(p) for p in backend) and any(is_frontend_client(p) for p in frontend)

        full_invocations += len(full_wf)
        split_invocations += len(backend_wf) + len(frontend_wf)
        duplicated_invocations += len(duplicated)
        shared_paths_total += len(shared)
        changes_with_shared += int(bool(shared))
        contract_sync_candidates += int(contract_sync)

        rows.append({
            "commit": commit,
            "backend_paths_n": len(backend),
            "frontend_paths_n": len(frontend),
            "shared_paths_n": len(shared),
            "shared_paths": shared,
            "contract_sync_candidate": contract_sync,
            "full_workflows": sorted(full_wf),
            "backend_workflows": sorted(backend_wf),
            "frontend_workflows": sorted(frontend_wf),
            "duplicated_workflows": sorted(duplicated),
        })

    n = len(cross_changes)
    extra_prs = n if n else 0
    extra_wf = split_invocations - full_invocations
    result = {
        "protocol": {
            "history_ref": history_ref,
            "history_sha": history_sha,
            "workflow_ref": workflow_ref,
            "workflow_sha": workflow_sha,
            "commit_window": WINDOW,
            "cross_boundary_population": "all",
        },
        "changes_n": n,
        "monorepo_min_pr_transactions": n,
        "split_min_pr_transactions": n * 2,
        "extra_pr_transactions_n": extra_prs,
        "extra_pr_transactions_ratio": (extra_prs / n if n else 0.0),
        "monorepo_min_revert_transactions": n,
        "split_min_revert_transactions": n * 2,
        "full_workflow_invocations_total": full_invocations,
        "split_workflow_invocations_total": split_invocations,
        "extra_workflow_invocations_n": extra_wf,
        "extra_workflow_invocations_ratio": (extra_wf / full_invocations if full_invocations else 0.0),
        "duplicated_workflow_invocations_n": duplicated_invocations,
        "changes_with_shared_paths_n": changes_with_shared,
        "changes_with_shared_paths_ratio": (changes_with_shared / n if n else 0.0),
        "shared_paths_total_n": shared_paths_total,
        "contract_sync_candidates_n": contract_sync_candidates,
        "contract_sync_candidates_ratio": (contract_sync_candidates / n if n else 0.0),
        "pr_workflows_n": len(workflows),
        "changes": rows,
    }

    out = ROOT / "artifacts" / "split-coordination-simulation.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k != "changes"}, indent=2))
    print(f"SPLIT_COORDINATION_SIMULATION={out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
