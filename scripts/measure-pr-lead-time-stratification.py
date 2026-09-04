#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import urllib.request
from datetime import datetime
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
HISTORY_REF = "53be795b6205ef57c03f1118e0c0287dc0f2873c"
WINDOW = 100
EXPECTED = {"backend_only": 25, "frontend_only": 11, "cross_boundary": 13}


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


def classify_commit(commit: str) -> tuple[str | None, list[str]]:
    paths = changed_paths(commit)
    classes = {classify_path(path) for path in paths}
    has_backend = "backend" in classes
    has_frontend = "frontend" in classes
    if not (has_backend or has_frontend):
        return None, paths
    if has_backend and has_frontend:
        return "cross_boundary", paths
    if has_backend:
        return "backend_only", paths
    return "frontend_only", paths


def api_json(url: str, token: str) -> object:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "bpt2-pr-lead-time-study",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def percentile(values: list[float], p: float) -> float | None:
    if not values:
        return None
    xs = sorted(values)
    if len(xs) == 1:
        return xs[0]
    pos = (len(xs) - 1) * p
    lo = int(pos)
    hi = min(lo + 1, len(xs) - 1)
    frac = pos - lo
    return xs[lo] + (xs[hi] - xs[lo]) * frac


def describe(values: list[float]) -> dict[str, float | int | None]:
    return {
        "n": len(values),
        "median_h": median(values) if values else None,
        "q1_h": percentile(values, 0.25),
        "q3_h": percentile(values, 0.75),
        "min_h": min(values) if values else None,
        "max_h": max(values) if values else None,
    }


def cliffs_delta(a: list[float], b: list[float]) -> float | None:
    if not a or not b:
        return None
    gt = 0
    lt = 0
    for x in a:
        for y in b:
            if x > y:
                gt += 1
            elif x < y:
                lt += 1
    return (gt - lt) / (len(a) * len(b))


def main() -> None:
    token = os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY", "tihotm/bpt2-abp")
    if not token:
        raise SystemExit("GITHUB_TOKEN is required")

    history_sha = git("rev-parse", HISTORY_REF)
    commits = git("rev-list", "--first-parent", f"--max-count={WINDOW}", history_sha).splitlines()
    classified: list[dict[str, object]] = []
    counts = {key: 0 for key in EXPECTED}
    for commit in commits:
        kind, paths = classify_commit(commit)
        if kind is None:
            continue
        counts[kind] += 1
        classified.append({"commit": commit, "classification": kind, "paths": paths})

    if counts != EXPECTED or len(classified) != sum(EXPECTED.values()):
        raise SystemExit(f"population mismatch: got {counts}, expected {EXPECTED}")

    rows: list[dict[str, object]] = []
    for item in classified:
        commit = str(item["commit"])
        pulls = api_json(f"https://api.github.com/repos/{repo}/commits/{commit}/pulls?per_page=100", token)
        if not isinstance(pulls, list):
            raise SystemExit(f"unexpected pulls response for {commit}")
        merged = [pr for pr in pulls if pr.get("merged_at") and pr.get("created_at")]
        row: dict[str, object] = {
            "commit": commit,
            "classification": item["classification"],
            "paths": item["paths"],
            "associated_pr_numbers": [pr.get("number") for pr in merged],
            "resolution": None,
        }
        if len(merged) == 0:
            row["resolution"] = "missing"
        elif len(merged) > 1:
            row["resolution"] = "ambiguous"
        else:
            pr = merged[0]
            created = parse_time(pr["created_at"])
            merged_at = parse_time(pr["merged_at"])
            lead_h = (merged_at - created).total_seconds() / 3600.0
            row.update({
                "resolution": "resolved",
                "pr_number": pr.get("number"),
                "pr_url": pr.get("html_url"),
                "created_at": pr.get("created_at"),
                "merged_at": pr.get("merged_at"),
                "merge_commit_sha": pr.get("merge_commit_sha"),
                "lead_time_h": lead_h,
            })
        rows.append(row)

    resolved = [row for row in rows if row["resolution"] == "resolved"]
    by_kind: dict[str, list[float]] = {key: [] for key in EXPECTED}
    for row in resolved:
        by_kind[str(row["classification"])].append(float(row["lead_time_h"]))
    single = by_kind["backend_only"] + by_kind["frontend_only"]
    cross = by_kind["cross_boundary"]

    single_median = median(single) if single else None
    cross_median = median(cross) if cross else None
    ratio = (cross_median / single_median) if cross_median is not None and single_median else None
    delta = cliffs_delta(cross, single)

    decision = "insufficient"
    if len(cross) >= 8 and len(single) >= 16 and ratio is not None and delta is not None:
        if 0.80 <= ratio <= 1.25 and abs(delta) < 0.33:
            decision = "no_material_difference_demonstrated"
        elif ratio >= 1.50 and delta >= 0.33:
            decision = "cross_boundary_higher_association"
        elif ratio <= 0.67 and delta <= -0.33:
            decision = "cross_boundary_lower_association"
        else:
            decision = "inconclusive_tradeoff"

    result = {
        "schema_version": 1,
        "tree_head": git("rev-parse", "HEAD"),
        "history_ref": HISTORY_REF,
        "history_sha": history_sha,
        "commit_window": WINDOW,
        "population_counts": counts,
        "resolved_n": len(resolved),
        "missing_n": sum(row["resolution"] == "missing" for row in rows),
        "ambiguous_n": sum(row["resolution"] == "ambiguous" for row in rows),
        "backend_only": describe(by_kind["backend_only"]),
        "frontend_only": describe(by_kind["frontend_only"]),
        "cross_boundary": describe(cross),
        "single_boundary": describe(single),
        "cross_vs_single": {
            "median_ratio": ratio,
            "median_difference_h": (cross_median - single_median) if cross_median is not None and single_median is not None else None,
            "cliffs_delta": delta,
            "decision": decision,
        },
        "rows": rows,
        "scope": "observational PR lead-time association in the frozen BPT2 monorepo history; not a causal multi-repo estimate",
    }

    output = ROOT / "artifacts" / "pr-lead-time-stratification.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in result.items() if key != "rows"}, indent=2, ensure_ascii=False))
    print(f"PR_LEAD_TIME_STRATIFICATION={output.relative_to(ROOT)}")

    if len(cross) < 8 or len(single) < 16:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
