# Current work

Last verified: **2026-08-30**

Snapshot volatile only.

## In flight

- Wave `PRODUCT-WAVE-SELLER-OPS-01`: Seller inventory/readiness drill-down and queue work surface.
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
| BR-04 | GitHub write not exercised in this wave | remote integration | no PR/merge performed | GitHub write access | yes |

## Immediate blocker

Frontend package checks cannot complete in this environment because `public-web` dependencies are not installed, so `eslint` is unavailable locally.

Remote PR/issue state used for reconstruction:

- `main` SHA: `df05fff0a62b5ae52450bde3f03d6ccc6539cc21`
- current checkout SHA: `8015e7dedcc932fc56ffdfc11e702a6869ab4d4c`
- open issues: `#160`
- open PRs: none
- merged PR relevant to current state: `#172`

## Next closure item

Continue the Seller Operations wave with any remaining repo-internal checkable gap, otherwise close as `COMPLETE_EXTERNAL_VALIDATION_PENDING` and move to remote integration.

## Canonical links

- [docs/PRODUCT.md](../PRODUCT.md)
- [docs/QUALITY.md](../QUALITY.md)
- [docs/LOCAL-DEVELOPMENT.md](../LOCAL-DEVELOPMENT.md)
- [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
- [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)
