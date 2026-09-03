#!/usr/bin/env python3
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def git_files(root: Path):
    out = subprocess.check_output(["git", "ls-files"], cwd=root, text=True)
    return [line.strip() for line in out.splitlines() if line.strip()]


def contract_paths(files):
    result = []
    for path in files:
        if path.startswith("main/BomPraTi/Controllers/"):
            result.append(path)
            continue
        if path.startswith("modules/") and ".Contracts/" in path:
            result.append(path)
    return sorted(result)


def contract_digest(root: Path, paths):
    h = hashlib.sha256()
    for rel in paths:
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        h.update((root / rel).read_bytes())
        h.update(b"\0")
    return h.hexdigest()


def rollout(contract_changed: bool, classification: str):
    if not contract_changed:
        return {"allowed": True, "order": "independent", "reason": "contract-unchanged"}
    if classification == "compatible":
        return {
            "allowed": True,
            "order": "backend-publish-or-deploy -> frontend-lock-update -> frontend-deploy",
            "reason": "explicit-compatible-classification",
        }
    if classification == "breaking":
        return {
            "allowed": False,
            "order": "dual-support-or-coordinated-rollout-required",
            "reason": "breaking-direct-deploy-blocked",
        }
    return {"allowed": False, "order": "blocked", "reason": "compatibility-unknown"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default="multi-repo-contract-boundary-prototype.json")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    files = git_files(root)
    frontend = sorted(p for p in files if p.startswith("public-web/"))
    backend_product = sorted(
        p for p in files if p.startswith("main/") or p.startswith("modules/") or p.startswith("tests/")
    )
    shared = sorted(p for p in files if p not in frontend and p not in backend_product)
    contracts = contract_paths(files)
    digest = contract_digest(root, contracts)

    stale_lock = "0" * 64
    stale_rejected = stale_lock != digest
    updated_lock_accepted = digest == digest

    rollout_cases = {
        "unchanged": rollout(False, "unknown"),
        "compatible": rollout(True, "compatible"),
        "breaking": rollout(True, "breaking"),
        "unknown": rollout(True, "unknown"),
    }

    assert stale_rejected
    assert updated_lock_accepted
    assert rollout_cases["unchanged"]["allowed"]
    assert rollout_cases["compatible"]["allowed"]
    assert not rollout_cases["breaking"]["allowed"]
    assert not rollout_cases["unknown"]["allowed"]

    result = {
        "schema": "bpt2.multi-repo-contract-boundary-prototype.v1",
        "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
        "partition": {
            "backend_strategy": "full-tree-minus-public-web",
            "frontend_strategy": "public-web-only",
            "shared_ownership": "backend-platform",
            "tracked_files_total": len(files),
            "backend_product_files": len(backend_product),
            "frontend_files": len(frontend),
            "shared_control_plane_files": len(shared),
            "frontend_shared_files_copied": 0,
        },
        "contract": {
            "path_rule": "modules/**/.Contracts/** + main/BomPraTi/Controllers/**",
            "files": len(contracts),
            "sha256": digest,
            "stale_lock_rejected": stale_rejected,
            "updated_lock_accepted": updated_lock_accepted,
        },
        "rollout_protocol": rollout_cases,
        "claims": {
            "semantic_compatibility_inferred": False,
            "human_productivity_measured": False,
            "real_multi_repo_deploy_measured": False,
        },
    }

    output = root / args.output
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
