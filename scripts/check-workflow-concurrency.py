#!/usr/bin/env python3
from pathlib import Path
import sys

WORKFLOWS = Path('.github/workflows')
GROUP = "  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}"
CANCEL = "  cancel-in-progress: ${{ github.event_name == 'pull_request' }}"


def main() -> int:
    failures: list[str] = []
    audited = 0

    for path in sorted(WORKFLOWS.glob('*.y*ml')):
        text = path.read_text(encoding='utf-8')
        if 'pull_request:' not in text:
            continue

        audited += 1
        lines = text.splitlines()
        try:
            concurrency_index = lines.index('concurrency:')
        except ValueError:
            failures.append(f'{path}: missing top-level concurrency block')
            continue

        block = lines[concurrency_index : concurrency_index + 3]
        expected = ['concurrency:', GROUP, CANCEL]
        if block != expected:
            failures.append(
                f'{path}: concurrency block must isolate github.workflow, '
                'reuse pull_request.number for superseded PR runs, fall back to '
                'run_id for non-PR events, and cancel only pull_request runs'
            )

    if audited == 0:
        failures.append('no pull_request workflows found')

    if failures:
        print('WORKFLOW_CONCURRENCY_GUARD=FAIL')
        for failure in failures:
            print(f'- {failure}')
        return 1

    print('WORKFLOW_CONCURRENCY_GUARD=PASS')
    print(f'PULL_REQUEST_WORKFLOWS_AUDITED={audited}')
    print('CROSS_WORKFLOW_CANCELLATION=REJECTED')
    print('NON_PR_GROUP_FALLBACK=RUN_ID')
    print('CANCEL_IN_PROGRESS_SCOPE=PULL_REQUEST_ONLY')
    return 0


if __name__ == '__main__':
    sys.exit(main())
