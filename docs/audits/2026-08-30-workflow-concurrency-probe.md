# Workflow concurrency probe — #166

Date: 2026-08-30
PR: #172

This file drives the predeclared rapid-synchronize experiment for workflow-scoped PR concurrency.

## Frozen contract

- group includes `github.workflow`;
- PR identity uses `github.event.pull_request.number`;
- non-PR fallback uses `github.run_id`;
- `cancel-in-progress` is true only for `pull_request` events;
- different workflows must not cancel one another;
- the newest PR head must survive.

## Probe sequence

- synchronize 1: emitted by this commit;
- synchronize 2: pending;
- synchronize 3: pending.

Final observations will replace the pending markers after run evidence is inspected.
