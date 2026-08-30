# Workflow concurrency probe — #166

Date: 2026-08-30
PR: #172

## Frozen contract

Every current `pull_request` workflow uses:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

A Harness guard rejects a missing or weakened contract.

## Controlled synchronize sequence

Three rapid synchronize commits were emitted after opening PR #172:

1. `5345765501b2562b54cadaebf02dc61a20a18d4e`
2. `966be61e8fcc8ec4418c8ee939733e88687a193f`
3. `e8a0e77d0655e40e9cc59a52f2a85abedfcb8879`

Each head generated all 26 current PR workflows because the PR changes every workflow file.

First observation of synchronize 1 showed 22/26 runs already completed with conclusion `cancelled`; the four remaining runs were still in progress while cancellation propagated. Synchronize 2 had its own 26 workflow identities, and synchronize 3 had 26 newest-head runs queued/pending with no cross-workflow cancellation observed.

The decisive final-head criterion remains: all 26 workflows on the final documented head must complete successfully before merge. Older probe heads are expected to converge to cancellation and are not merge authority.

## Disposition

`WORKFLOW_SCOPED_CONCURRENCY = IMPLEMENTED`

`CROSS_WORKFLOW_KEY_ISOLATION = PASS_BY_CONSTRUCTION_AND_OBSERVATION`

`SUPERSEDED_PR_RUN_CANCELLATION = EMPIRICALLY_REPRODUCED`

`NON_PR_GROUP_FALLBACK = github.run_id`

`NON_PR_CANCEL_IN_PROGRESS = false`

`FINAL_HEAD_CI = REQUIRED_BEFORE_MERGE`

No product, schema, dependency, trigger path-set, permission, deployment or release behavior is changed by this slice.
