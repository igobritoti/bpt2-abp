#!/usr/bin/env python3
from __future__ import annotations

import json
import math
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


def parent_of(commit: str) -> str | None:
    parts = git("rev-list", "--parents", "-n", "1", commit).split()
    return parts[1] if len(parts) > 1 else None


def changed_paths(commit: str) -> list[str]:
    parent = parent_of(commit)
    out = git("diff", "--name-only", parent, commit) if parent else git("show", "--pretty=", "--name-only", commit)
    return [line for line in out.splitlines() if line]


def churn(commit: str) -> tuple[int, int]:
    parent = parent_of(commit)
    out = git("diff", "--numstat", parent, commit) if parent else git("show", "--pretty=", "--numstat", commit)
    additions = deletions = 0
    for line in out.splitlines():
        parts = line.split("\t", 2)
        if len(parts) < 3 or parts[0] == "-" or parts[1] == "-":
            continue
        additions += int(parts[0])
        deletions += int(parts[1])
    return additions, deletions


def classify_commit(commit: str) -> tuple[str | None, list[str]]:
    paths = changed_paths(commit)
    classes = {classify_path(path) for path in paths}
    has_backend = "backend" in classes
    has_frontend = "frontend" in classes
    if not (has_backend or has_frontend):
        return None, paths
    if has_backend and has_frontend:
        return "cross_boundary", paths
    return ("backend_only" if has_backend else "frontend_only"), paths


def api_json(url: str, token: str) -> object:
    req = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "bpt2-pr-lead-time-size-adjusted",
    })
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
    lo = int(pos); hi = min(lo + 1, len(xs) - 1); frac = pos - lo
    return xs[lo] + (xs[hi] - xs[lo]) * frac


def describe(values: list[float]) -> dict[str, float | int | None]:
    return {"n": len(values), "median": median(values) if values else None,
            "q1": percentile(values, 0.25), "q3": percentile(values, 0.75),
            "min": min(values) if values else None, "max": max(values) if values else None}


def cliffs_delta(a: list[float], b: list[float]) -> float | None:
    if not a or not b:
        return None
    gt = lt = 0
    for x in a:
        for y in b:
            if x > y: gt += 1
            elif x < y: lt += 1
    return (gt - lt) / (len(a) * len(b))


def invert(a: list[list[float]]) -> list[list[float]]:
    n = len(a)
    aug = [row[:] + [1.0 if i == j else 0.0 for j in range(n)] for i, row in enumerate(a)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(aug[r][col]))
        if abs(aug[pivot][col]) < 1e-12:
            raise ValueError("singular matrix")
        aug[col], aug[pivot] = aug[pivot], aug[col]
        div = aug[col][col]
        aug[col] = [v / div for v in aug[col]]
        for r in range(n):
            if r == col: continue
            f = aug[r][col]
            aug[r] = [aug[r][c] - f * aug[col][c] for c in range(2*n)]
    return [row[n:] for row in aug]


def matmul(a: list[list[float]], b: list[list[float]]) -> list[list[float]]:
    return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]


def transpose(a: list[list[float]]) -> list[list[float]]:
    return [list(x) for x in zip(*a)]


def ols_hc3(rows: list[dict[str, object]]) -> dict[str, object]:
    X = [[1.0, 1.0 if r["classification"] == "cross_boundary" else 0.0,
          math.log1p(float(r["churn"])), math.log1p(float(r["files_changed"]))] for r in rows]
    y = [[math.log1p(float(r["lead_time_h"]))] for r in rows]
    Xt = transpose(X); XtX = matmul(Xt, X); inv = invert(XtX)
    beta_m = matmul(matmul(inv, Xt), y); beta = [v[0] for v in beta_m]
    fitted = [sum(X[i][j] * beta[j] for j in range(4)) for i in range(len(X))]
    residual = [y[i][0] - fitted[i] for i in range(len(X))]
    h = []
    for x in X:
        h.append(sum(x[j] * inv[j][k] * x[k] for j in range(4) for k in range(4)))
    meat = [[0.0]*4 for _ in range(4)]
    for i, x in enumerate(X):
        scale = (residual[i] / max(1e-9, 1.0 - h[i])) ** 2
        for j in range(4):
            for k in range(4):
                meat[j][k] += scale * x[j] * x[k]
    cov = matmul(matmul(inv, meat), inv)
    se = [math.sqrt(max(0.0, cov[i][i])) for i in range(4)]
    z = [beta[i] / se[i] if se[i] > 0 else None for i in range(4)]
    p = [math.erfc(abs(v)/math.sqrt(2.0)) if v is not None else None for v in z]
    ybar = sum(v[0] for v in y) / len(y)
    sse = sum(e*e for e in residual); sst = sum((v[0]-ybar)**2 for v in y)
    names = ["intercept", "cross_boundary", "log1p_churn", "log1p_files_changed"]
    return {"n": len(rows), "r_squared": 1.0 - sse/sst if sst else None,
            "coefficients": {names[i]: {"beta": beta[i], "hc3_se": se[i], "z": z[i], "p_normal_approx": p[i]} for i in range(4)}}


def main() -> None:
    token = os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY", "tihotm/bpt2-abp")
    if not token: raise SystemExit("GITHUB_TOKEN is required")
    commits = git("rev-list", "--first-parent", f"--max-count={WINDOW}", HISTORY_REF).splitlines()
    counts = {k: 0 for k in EXPECTED}; classified = []
    for commit in commits:
        kind, paths = classify_commit(commit)
        if kind is None: continue
        counts[kind] += 1
        adds, dels = churn(commit)
        classified.append({"commit": commit, "classification": kind, "paths": paths,
                           "additions": adds, "deletions": dels, "churn": adds+dels, "files_changed": len(paths)})
    if counts != EXPECTED: raise SystemExit(f"population mismatch: {counts}")

    rows = []
    for item in classified:
        pulls = api_json(f"https://api.github.com/repos/{repo}/commits/{item['commit']}/pulls?per_page=100", token)
        merged = [pr for pr in pulls if pr.get("merged_at") and pr.get("created_at")]
        row = dict(item); row["associated_pr_numbers"] = [pr.get("number") for pr in merged]
        if len(merged) != 1:
            row["resolution"] = "missing" if len(merged) == 0 else "ambiguous"
        else:
            pr = merged[0]; row["resolution"] = "resolved"; row["pr_number"] = pr.get("number")
            row["lead_time_h"] = (parse_time(pr["merged_at"]) - parse_time(pr["created_at"])).total_seconds()/3600.0
        rows.append(row)
    resolved = [r for r in rows if r["resolution"] == "resolved"]
    cross = [r for r in resolved if r["classification"] == "cross_boundary"]
    single = [r for r in resolved if r["classification"] != "cross_boundary"]

    available = single[:]; pairs = []
    for c in sorted(cross, key=lambda r: (math.log1p(float(r["churn"])), str(r["commit"]))):
        if not available: break
        s = min(available, key=lambda r: (abs(math.log1p(float(c["churn"])) - math.log1p(float(r["churn"]))),
                                          abs(math.log1p(float(c["files_changed"])) - math.log1p(float(r["files_changed"]))), str(r["commit"])))
        available.remove(s)
        pairs.append({"cross_commit": c["commit"], "single_commit": s["commit"],
                      "cross_churn": c["churn"], "single_churn": s["churn"],
                      "cross_files": c["files_changed"], "single_files": s["files_changed"],
                      "cross_lead_h": c["lead_time_h"], "single_lead_h": s["lead_time_h"]})
    cross_lead = [float(p["cross_lead_h"]) for p in pairs]; single_lead = [float(p["single_lead_h"]) for p in pairs]
    cm = median(cross_lead) if cross_lead else None; sm = median(single_lead) if single_lead else None
    ratio = cm/sm if cm is not None and sm else None; delta = cliffs_delta(cross_lead, single_lead)
    decision = "insufficient"
    if len(pairs) >= 8 and ratio is not None and delta is not None:
        if ratio >= 1.50 and delta >= 0.33: decision = "higher_association_persists_after_size_matching"
        elif 0.80 <= ratio <= 1.25 and abs(delta) < 0.33: decision = "compatible_with_substantial_size_confounding"
        else: decision = "inconclusive_tradeoff"
    regression = ols_hc3(resolved)
    result = {
        "schema_version": 1, "tree_head": git("rev-parse", "HEAD"), "history_ref": HISTORY_REF,
        "population_counts": counts, "resolved_n": len(resolved),
        "missing_n": sum(r["resolution"] == "missing" for r in rows),
        "ambiguous_n": sum(r["resolution"] == "ambiguous" for r in rows),
        "size_by_group": {
            "cross_churn": describe([float(r["churn"]) for r in cross]),
            "single_churn": describe([float(r["churn"]) for r in single]),
            "cross_files": describe([float(r["files_changed"]) for r in cross]),
            "single_files": describe([float(r["files_changed"]) for r in single]),
        },
        "matching": {"pairs_n": len(pairs), "cross_lead": describe(cross_lead), "single_lead": describe(single_lead),
                     "median_ratio": ratio, "cliffs_delta": delta, "decision": decision, "pairs": pairs},
        "regression": regression,
        "rows": rows,
        "scope": "observational size-adjusted association in frozen BPT2 monorepo history; not causal architecture evidence"
    }
    out = ROOT / "artifacts" / "pr-lead-time-size-adjusted.json"; out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    print(json.dumps({k:v for k,v in result.items() if k != "rows"}, indent=2, ensure_ascii=False))
    print(f"PR_LEAD_TIME_SIZE_ADJUSTED={out.relative_to(ROOT)}")
    if len(pairs) < 8: raise SystemExit(2)

if __name__ == "__main__": main()
