# Current work

Last verified: **2026-08-31**

Snapshot volatile only.

## In flight

- Wave `PRODUCT-WAVE-SELLER-OPS-01`: Seller inventory/readiness drill-down and queue work surface.
- The wave is published on remote branch `chore/workflow-scoped-concurrency-166` and tracked by PR [#175](https://github.com/tihotm/bpt2-abp/pull/175).
- Wave block completed locally:
  - inventory status queues now expose direct lifecycle actions where backend allows them;
  - listing edit surface now shows current lifecycle context and publish authority instead of an invented readiness checklist;
  - publication readiness is reduced to actual mutability/canonical-vehicle authority.
- Current control-plane artifacts:
  - [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
  - [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)

## Blocker register

| ID | Blocker | Affects | Evidence | Required unblock | Can wave continue? |
| --- | --- | --- | --- | --- | --- |
| BR-01 | `npm ci` fails in `public-web` | frontend validation | `EACCES` on registry fetch and `EPERM` cleanup in existing `node_modules`, even after deleting local `node_modules` once | clean writable install state and registry access | yes |
| BR-02 | `npm run check` unavailable in current `public-web` environment | frontend validation | `eslint` not available before/without successful dependency restore | dependency restore | yes |
| BR-03 | Browser/DB runtime unavailable on this machine | end-to-end Seller smoke | previous documented fresh-environment probe remains blocked by missing disposable runtime | PostgreSQL-capable runtime / browser smoke env | yes |
| BR-04 | GitHub PR inspection is inconsistent through `gh` GraphQL | remote integration follow-through | `gh pr view` and `gh pr checks` returned `HTTP 401`, while REST `gh api repos/tihotm/bpt2-abp/pulls/175` succeeds | stable GitHub API access or direct web review | yes |

## Immediate blocker

Frontend package checks cannot complete in this environment because `public-web` dependencies are not installed, so `eslint` is unavailable locally.

## Remote integration state

- remote repository moved to `tihotm/bpt2-abp`;
- PR [#175](https://github.com/tihotm/bpt2-abp/pull/175) exists and is open;
- `main` on the remote remains at the reconstruction baseline until PR #175 merges.

## Next closure item

Continue the Seller Operations wave with any remaining repo-internal checkable gap, otherwise keep the current wave in `COMPLETE_EXTERNAL_VALIDATION_PENDING` while remote review/CI finalizes.

## Canonical links

- [docs/PRODUCT.md](../PRODUCT.md)
- [docs/QUALITY.md](../QUALITY.md)
- [docs/LOCAL-DEVELOPMENT.md](../LOCAL-DEVELOPMENT.md)
- [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
- [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)

## Source of runtime truth

- product: [`../PRODUCT.md`](../PRODUCT.md);
- coverage: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md);
- discovery baseline: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md);
- typo scoring: [`../audits/2026-08-30-discovery-typo-scoring-comparison.md`](../audits/2026-08-30-discovery-typo-scoring-comparison.md);
- metamorphic: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md);
- workflow concurrency: [`../audits/2026-08-30-workflow-concurrency-probe.md`](../audits/2026-08-30-workflow-concurrency-probe.md);
- generated facts: [`../generated/repository-facts.md`](../generated/repository-facts.md).

## Update rule

Atualize somente quando mudar outcome, plano, acceptance target ou blocker real.
