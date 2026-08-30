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

- synchronize 1: emitted by `5345765501b2562b54cadaebf02dc61a20a18d4e`;
- synchronize 2: emitted by `966be61e8fcc8ec4418c8ee939733e88687a193f`;
- synchronize 3: emitted by this commit.

Final observations will replace this sentence after run evidence is inspected.
