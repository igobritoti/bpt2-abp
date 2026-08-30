# Saved Search PostgreSQL claim baseline

Date: 2026-08-29
Authority: issue #117
PR: #132

## Question

Can the existing `SavedSearchAlertDetectionRequest` ledger support cross-worker ownership and recovery using PostgreSQL transaction semantics before BPT2 selects a scheduler, lease schema, retry policy, or additional infrastructure?

## Experimental boundary

The benchmark uses PostgreSQL 17 and the existing request/match ledgers. A worker opens a transaction and selects the oldest pending request using `FOR UPDATE SKIP LOCKED LIMIT 1`. No claim columns, lease timestamps, scheduler, Redis, Hangfire, Quartz, ABP Background Jobs adoption, poll interval, retry/backoff threshold, or automatic production runner is introduced.

The experiment measures coordination/recovery only. Existing Saved Search matching correctness remains owned by the Buyer HTTP gate and `scripts/buyer-saved-search-http-smoke.sh`.

## Executed evidence

Green run: `33282515587`
Artifact: `9723418523`
Artifact ZIP SHA-256: `d14fbd80aeb82c3289625afe80d36d7ca3dd27c109f4890560e6440be8c893b9`
Schema: `bpt2.saved-search-postgres-claim-baseline.v1`
Fresh Migration Gate: passed.

Observed invariants:

- simultaneous workers claimed different pending request IDs;
- rollback made the unfinished request eligible for a later worker;
- a durable Saved Search/Listing match survived owner rollback and replay converged to exactly one match;
- a locked slow item did not prevent an independent pending item from progressing;
- cancellation-equivalent rollback allowed recovery;
- completed requests were not reclaimed;
- concurrent enqueue converged to one durable request row; the competing insert hit the unique constraint, establishing uniqueness as a backstop rather than a worker-coordination protocol.

Timing observations from this CI run:

- first claim/warm-up: `314.3055 ms`;
- concurrent second worker claim: `8.3492 ms`;
- reclaim after rollback: `2.2502 ms`;
- observed reclaim transaction duration: `9.1788 ms`.

These values characterize one hosted CI execution. They are not SLOs, product thresholds, lease durations, poll intervals, or retry parameters.

## Decision

`POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED`

`MATCH_LEDGER_REPLAY_IDEMPOTENCY = PROVED_BOUNDED`

`UNIQUE_CONSTRAINT_AS_WORKER_COORDINATION = REJECTED`

`DURABLE_CLAIM_COLUMNS = NOT_JUSTIFIED_YET`

`AUTOMATIC_RUNNER = NOT_YET_AUTHORIZED`

`PRODUCTION_DEPLOYMENT_TOPOLOGY = STILL_UNESTABLISHED`

`POLL_LEASE_RETRY_THRESHOLDS = UNSET`

`HANGFIRE_QUARTZ_REDIS = NOT_JUSTIFIED`

## Remaining release boundary

This benchmark does not establish where/how many runner instances execute in production, process lifetime/shutdown guarantees, scheduling cadence, retry/backoff policy, transaction boundary across full detection, or external notification delivery. Issue #117 therefore remains open after this benchmark is merged. A production runner is only authorized after those operational facts are fixed and recovery is re-tested against that concrete topology.
