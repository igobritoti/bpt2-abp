#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path

CHECKER = Path(__file__).with_name("check-harness.py")
spec = importlib.util.spec_from_file_location("check_harness", CHECKER)
if spec is None or spec.loader is None:
    raise RuntimeError("unable to load check-harness.py")
check_harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check_harness)


def run_check(root: Path) -> list[str]:
    previous_root = check_harness.ROOT
    check_harness.ROOT = root
    try:
        errors: list[str] = []
        check_harness.check_http_smoke_wiring(errors)
        return errors
    finally:
        check_harness.ROOT = previous_root


def main() -> int:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        scripts = root / "scripts"
        workflows = root / ".github/workflows"
        scripts.mkdir(parents=True)
        workflows.mkdir(parents=True)

        smoke = scripts / "example-http-smoke.sh"
        smoke.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
        workflow = workflows / "example.yml"

        workflow.write_text(
            "steps:\n  - run: bash -n scripts/example-http-smoke.sh\n",
            encoding="utf-8",
        )
        syntax_only_errors = run_check(root)
        assert syntax_only_errors == [
            "HTTP smoke is not executed by any root workflow: scripts/example-http-smoke.sh"
        ], syntax_only_errors

        workflow.write_text(
            "steps:\n  - run: bash scripts/example-http-smoke.sh\n",
            encoding="utf-8",
        )
        executed_errors = run_check(root)
        assert executed_errors == [], executed_errors

    print("HTTP SMOKE WIRING CHECK: PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
