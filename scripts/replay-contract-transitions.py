#!/usr/bin/env python3
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

COMMITS = [
    "eaf2a49b88453f751782fb2a5bc49f4170fe38f8",
    "b6a9e2e693be2a80de32cdc38ee52ca910a44de2",
    "39ed3fec59db3211d44e58fba56e874b494106a7",
    "36195602e965f4b6cc99f436768a644e77d11252",
    "688157b93f046c3850ddd169449b9b1fa94b1848",
    "88f3bd355c46aa2cc1e8ff188c43866eb2e00e6f",
    "a02fd6d311f88944b12a332617ef42c138f483e6",
    "20561030611e802bad51d07476f5f77b3234310a",
    "3aae3379de909ab9ed4a0a70ee931035803af55f",
    "1471de8f69d0216f09d6c42c57a2ccbba900b2d7",
    "d610b0f0a5bd244da9e8504265f667e0e2416d95",
    "207ae3bf064e90b37cb094d86ef626be9d6ca48c",
    "29e4d5fde05f8dd1a84a3146d789a5e2e7efbf87",
]


def git(root: Path, *args: str, text: bool = True):
    return subprocess.check_output(["git", *args], cwd=root, text=text)


def is_contract_path(path: str) -> bool:
    return path.startswith("main/BomPraTi/Controllers/") or (
        path.startswith("modules/") and ".Contracts/" in path
    )


def is_backend_contract_signal(path: str) -> bool:
    return ".Contracts/" in path or path.startswith("main/BomPraTi/Controllers/")


def is_frontend_client_signal(path: str) -> bool:
    return path.startswith("public-web/lib/") or path.startswith("public-web/app/api/")


def tree_paths(root: Path, ref: str):
    out = git(root, "ls-tree", "-r", "--name-only", ref)
    return sorted(line for line in out.splitlines() if line and is_contract_path(line))


def contract_digest(root: Path, ref: str):
    paths = tree_paths(root, ref)
    h = hashlib.sha256()
    for path in paths:
        h.update(path.encode("utf-8"))
        h.update(b"\0")
        h.update(git(root, "show", f"{ref}:{path}", text=False))
        h.update(b"\0")
    return h.hexdigest(), paths


def changed_paths(root: Path, parent: str, commit: str):
    out = git(root, "diff", "--name-status", "--find-renames", parent, commit)
    paths = []
    rows = []
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        changed = parts[1:]
        for path in changed:
            paths.append(path)
        rows.append({"status": status, "paths": changed})
    return sorted(set(paths)), rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default="contract-transition-replay.json")
    args = parser.parse_args()
    root = Path(args.root).resolve()

    assert len(COMMITS) == 13
    cases = []
    candidates = 0
    actual_changes = 0
    false_positives = 0
    stale_lock_cases = 0
    compatible_checkpoints = 0
    breaking_checkpoints = 0

    for commit in COMMITS:
        subprocess.check_call(["git", "cat-file", "-e", f"{commit}^{{commit}}"], cwd=root)
        parent = git(root, "rev-parse", f"{commit}^").strip()
        paths, diff_rows = changed_paths(root, parent, commit)
        backend_signal = any(is_backend_contract_signal(p) for p in paths)
        frontend_signal = any(is_frontend_client_signal(p) for p in paths)
        candidate = backend_signal and frontend_signal
        before_digest, before_contract_paths = contract_digest(root, parent)
        after_digest, after_contract_paths = contract_digest(root, commit)
        changed = before_digest != after_digest
        contract_changed_paths = sorted(p for p in paths if is_contract_path(p))

        if candidate:
            candidates += 1
            if changed:
                actual_changes += 1
                stale_lock_cases += 1
                compatible_checkpoints += 4
                breaking_checkpoints += 6
            else:
                false_positives += 1

        cases.append({
            "commit": commit,
            "parent": parent,
            "changed_paths_total": len(paths),
            "contract_sync_candidate": candidate,
            "backend_contract_signal": backend_signal,
            "frontend_client_signal": frontend_signal,
            "contract_changed": changed,
            "contract_digest_before": before_digest,
            "contract_digest_after": after_digest,
            "contract_files_before": len(before_contract_paths),
            "contract_files_after": len(after_contract_paths),
            "contract_changed_paths": contract_changed_paths,
            "contract_changed_paths_count": len(contract_changed_paths),
            "compatible_checkpoints": 4 if candidate and changed else 0,
            "breaking_checkpoints": 6 if candidate and changed else 0,
            "diff_rows": diff_rows,
        })

    assert candidates == 12, f"expected 12 historical candidates, got {candidates}"
    ratio = actual_changes / candidates if candidates else 0.0
    result = {
        "schema": "bpt2.contract-transition-replay.v1",
        "source_head": git(root, "rev-parse", "HEAD").strip(),
        "population_commits": len(COMMITS),
        "contract_sync_candidates": candidates,
        "contract_sync_candidates_ratio": candidates / len(COMMITS),
        "actual_contract_changes": actual_changes,
        "actual_contract_changes_ratio_among_candidates": ratio,
        "heuristic_false_positives": false_positives,
        "stale_lock_cases": stale_lock_cases,
        "compatible_checkpoints_total": compatible_checkpoints,
        "breaking_checkpoints_total": breaking_checkpoints,
        "unknown_rollout_allowed": False,
        "semantic_compatibility_inferred": False,
        "cases": cases,
    }
    assert result["unknown_rollout_allowed"] is False

    output = root / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
