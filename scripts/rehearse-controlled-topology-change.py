#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_REL = Path("modules/catalog/src/BomPraTi.Catalog.Contracts/VehicleRefDto.cs")
CONSUMER_REL = Path("public-web/lib/topology-probe.ts")
BASE_TAIL = "    string? Transmission,\n    string? BodyStyle);\n"
CHANGED_TAIL = "    string? Transmission,\n    string? BodyStyle,\n    string? TopologyProbeLabel = null);\n"
CONSUMER = """export type TopologyProbeVehicle = {\n  topologyProbeLabel?: string | null;\n};\n\nexport function topologyProbeLabel(vehicle: TopologyProbeVehicle): string {\n  return vehicle.topologyProbeLabel?.trim() || \"unlabeled\";\n}\n"""


def timed(cmd: list[str], cwd: Path) -> tuple[float, int]:
    start = time.monotonic()
    proc = subprocess.run(cmd, cwd=cwd, check=False)
    return time.monotonic() - start, proc.returncode


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def change_fingerprint() -> str:
    return digest_bytes((CHANGED_TAIL + "\0" + CONSUMER).encode("utf-8"))


def copy_combined(dst: Path) -> float:
    start = time.monotonic()
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns(".git", "artifacts", "node_modules", ".next", "bin", "obj"))
    return time.monotonic() - start


def copy_backend(dst: Path) -> float:
    start = time.monotonic()
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns(".git", "public-web", "artifacts", "node_modules", ".next", "bin", "obj"))
    return time.monotonic() - start


def copy_frontend(dst: Path) -> float:
    start = time.monotonic()
    shutil.copytree(ROOT / "public-web", dst, ignore=shutil.ignore_patterns("node_modules", ".next"))
    return time.monotonic() - start


def patch_backend(root: Path) -> tuple[float, str, str]:
    path = root / CONTRACT_REL
    before = path.read_bytes()
    text = before.decode("utf-8")
    if BASE_TAIL not in text:
        raise RuntimeError("VehicleRefDto baseline shape changed; workload invalid")
    start = time.monotonic()
    path.write_text(text.replace(BASE_TAIL, CHANGED_TAIL, 1), encoding="utf-8")
    elapsed = time.monotonic() - start
    after = path.read_bytes()
    if before == after:
        raise RuntimeError("backend patch produced no change")
    return elapsed, digest_bytes(before), digest_bytes(after)


def patch_frontend(frontend_root: Path) -> float:
    path = frontend_root / "lib" / "topology-probe.ts"
    if path.exists():
        raise RuntimeError("topology probe consumer unexpectedly exists in baseline")
    start = time.monotonic()
    path.write_text(CONSUMER, encoding="utf-8")
    return time.monotonic() - start


def check_consumer(frontend_root: Path) -> bool:
    text = (frontend_root / "lib" / "topology-probe.ts").read_text(encoding="utf-8")
    return "topologyProbeLabel?.trim()" in text and '"unlabeled"' in text


def combined(rep: int) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix=f"bpt2-topology-combined-{rep}-") as td:
        tree = Path(td) / "repo"
        materialize_s = copy_combined(tree)
        backend_patch_s, before_digest, after_digest = patch_backend(tree)
        frontend_patch_s = patch_frontend(tree / "public-web")
        backend_s, backend_rc = timed(["dotnet", "build", "main/BomPraTi/BomPraTi.csproj", "--configuration", "Release", "--nologo"], tree)
        install_s, install_rc = timed(["npm", "ci", "--no-audit", "--no-fund"], tree / "public-web")
        check_s, check_rc = timed(["npm", "run", "check"], tree / "public-web")
        consumer_ok = check_consumer(tree / "public-web")
        total = materialize_s + backend_patch_s + frontend_patch_s + backend_s + install_s + check_s
        return {
            "materialize_s": materialize_s,
            "backend_patch_s": backend_patch_s,
            "frontend_patch_s": frontend_patch_s,
            "backend_build_s": backend_s,
            "frontend_install_s": install_s,
            "frontend_check_s": check_s,
            "compute_s": total,
            "critical_path_s": total,
            "contract_before_sha256": before_digest,
            "contract_after_sha256": after_digest,
            "integration_transactions": 1,
            "contract_handoffs": 0,
            "checkpoints": 1,
            "consumer_ok": consumer_ok,
            "pass": backend_rc == 0 and install_rc == 0 and check_rc == 0 and consumer_ok,
        }


def split(rep: int) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix=f"bpt2-topology-split-{rep}-") as td:
        base = Path(td)
        backend = base / "backend"
        frontend = base / "frontend"
        backend_materialize_s = copy_backend(backend)
        frontend_materialize_s = copy_frontend(frontend)

        backend_patch_s, before_digest, after_digest = patch_backend(backend)
        backend_build_s, backend_rc = timed(["dotnet", "build", "main/BomPraTi/BomPraTi.csproj", "--configuration", "Release", "--nologo"], backend)

        handoff_start = time.monotonic()
        contract_lock = after_digest
        handoff_s = time.monotonic() - handoff_start
        frontend_patch_s = patch_frontend(frontend)
        lock_accepted = contract_lock == after_digest and contract_lock != before_digest

        install_s, install_rc = timed(["npm", "ci", "--no-audit", "--no-fund"], frontend)
        check_s, check_rc = timed(["npm", "run", "check"], frontend)
        consumer_ok = check_consumer(frontend)

        backend_stream = backend_materialize_s + backend_patch_s + backend_build_s + handoff_s
        frontend_stream = frontend_materialize_s + frontend_patch_s + install_s + check_s
        compute = backend_stream + frontend_stream
        return {
            "backend_materialize_s": backend_materialize_s,
            "frontend_materialize_s": frontend_materialize_s,
            "backend_patch_s": backend_patch_s,
            "contract_handoff_s": handoff_s,
            "frontend_patch_s": frontend_patch_s,
            "backend_build_s": backend_build_s,
            "frontend_install_s": install_s,
            "frontend_check_s": check_s,
            "backend_stream_s": backend_stream,
            "frontend_stream_s": frontend_stream,
            "compute_s": compute,
            "critical_path_s": max(backend_stream, frontend_stream),
            "contract_before_sha256": before_digest,
            "contract_after_sha256": after_digest,
            "contract_lock_accepted": lock_accepted,
            "integration_transactions": 2,
            "contract_handoffs": 1,
            "checkpoints": 3,
            "consumer_ok": consumer_ok,
            "pass": backend_rc == 0 and install_rc == 0 and check_rc == 0 and consumer_ok and lock_accepted,
        }


def ratio(a: float, b: float) -> float | None:
    return a / b if b else None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pairs", type=int, default=3)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    observations: list[dict[str, object]] = []
    fingerprint = change_fingerprint()
    for rep in range(1, args.pairs + 1):
        order = ["combined", "split"] if rep % 2 else ["split", "combined"]
        row: dict[str, object] = {"pair": rep, "order": order, "change_fingerprint": fingerprint}
        for condition in order:
            row[condition] = combined(rep) if condition == "combined" else split(rep)
        c = row["combined"]
        s = row["split"]
        assert isinstance(c, dict) and isinstance(s, dict)
        same_contract_change = c["contract_before_sha256"] == s["contract_before_sha256"] and c["contract_after_sha256"] == s["contract_after_sha256"]
        row["same_logical_change"] = same_contract_change
        row["valid"] = bool(c["pass"] and s["pass"] and same_contract_change)
        observations.append(row)

    valid = [row for row in observations if row["valid"]]
    summary: dict[str, object] = {
        "required_pairs": args.pairs,
        "valid_pairs": len(valid),
        "change_fingerprint": fingerprint,
        "combined_integration_transactions": 1,
        "split_integration_transactions": 2,
        "combined_contract_handoffs": 0,
        "split_contract_handoffs": 1,
        "combined_checkpoints": 1,
        "split_checkpoints": 3,
    }
    if valid:
        c_compute = median(float(row["combined"]["compute_s"]) for row in valid)
        s_compute = median(float(row["split"]["compute_s"]) for row in valid)
        c_critical = median(float(row["combined"]["critical_path_s"]) for row in valid)
        s_critical = median(float(row["split"]["critical_path_s"]) for row in valid)
        summary.update({
            "combined_compute_median_s": c_compute,
            "split_compute_median_s": s_compute,
            "split_compute_vs_combined_ratio": ratio(s_compute, c_compute),
            "combined_critical_path_median_s": c_critical,
            "split_critical_path_median_s": s_critical,
            "split_critical_vs_combined_ratio": ratio(s_critical, c_critical),
            "split_compute_delta_pct": ((s_compute / c_compute) - 1.0) * 100.0 if c_compute else None,
            "split_critical_delta_pct": ((s_critical / c_critical) - 1.0) * 100.0 if c_critical else None,
        })

    payload = {
        "schema_version": 1,
        "head_sha": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "github_event_sha": os.getenv("GITHUB_SHA"),
        "workload": {
            "contract_path": str(CONTRACT_REL),
            "consumer_path": str(CONSUMER_REL),
            "backend_change": "append optional string? TopologyProbeLabel = null",
            "frontend_change": "typed optional topologyProbeLabel consumer with unlabeled fallback",
            "source_tree_mutated": False,
        },
        "pairs": observations,
        "summary": summary,
        "scope": "controlled compatible contract-consumer workload using real BPT2 build/checks; not a production feature, human-productivity study, or real two-runner deployment measurement",
    }
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2, sort_keys=True))
    if len(valid) < args.pairs:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
