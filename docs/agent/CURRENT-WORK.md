# Current work

Last verified: **2026-08-31**

Snapshot volatile only.

## In flight

- Wave `PRODUCT-WAVE-PUBLIC-SELLER-EXPERIENCE-01`: public Seller Hub continuity from Listing detail to Seller inventory and back navigation.
- Local public Seller experience patch is in place:
  - public Listing cards preserve the current discovery state as `returnTo` when opening a listing detail;
  - listing detail back navigation restores the caller discovery state when `returnTo` is present;
  - public Seller Hub uses only authorized Seller data, shows public inventory only, and renders an empty state when no public inventory is available;
  - public Listing detail now links to the Seller Hub through the authorized public Seller projection.
- Repo-internal validation that passed on this slice:
  - `npm run lint` in `public-web`;
  - `npm run typecheck` in `public-web`;
  - `npm run build` in `public-web` with `BPT_PUBLIC_BASE_URL` and `BPT_API_BASE_URL` defined;
  - `dotnet build tests/BomPraTi.Gate01Smoke/BomPraTi.Gate01Smoke.csproj`.
- Remote integration state:
  - branch `codex/public-seller-experience-01` pushed to `origin`;
  - PR [#177](https://github.com/tihotm/bpt2-abp/pull/177) opened against `main`;
  - GitHub CLI check inspection is blocked by `HTTP 401` on the current credential.
- Current control-plane artifacts:
  - [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
  - [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)

## Blocker register

| ID | Blocker | Affects | Evidence | Required unblock | Can wave continue? |
| --- | --- | --- | --- | --- | --- |
| BR-01 | Browser/DB runtime unavailable on this machine | end-to-end public Seller / Buyer smoke | `BPT_DB_CONNECTION`, `BPT_FIXTURE_VEHICLE_ID`, and `BPT_PUBLIC_BASE_URL` are absent on this machine | PostgreSQL-capable runtime / browser smoke env | yes |
| BR-02 | `#160` main-branch integration policy remains administrative | repository administration | open issue #160 and branch-protection/ruleset enforcement remain unresolved | repository administration authority | yes |
| BR-03 | GitHub CLI/API auth unavailable for PR inspection | remote CI / mergeability | `gh pr checks 177` returned `HTTP 401: Requires authentication` | authenticated GitHub access | yes |

## Immediate blocker

Repo-internal work is integrated locally. Remaining validation is external/remote: browser/DB smoke, repository administration, and authenticated PR inspection/merge.

## Remote integration state

- PR [#177](https://github.com/tihotm/bpt2-abp/pull/177) is open for this slice;
- remote repository remains `tihotm/bpt2-abp`;
- current worktree/branch contains the local public Seller experience patch awaiting CI and merge.

## Next closure item

Keep the current wave in `COMPLETE_REMOTE_INTEGRATION_PENDING` while the remaining remote CI/mergeability, browser/DB smoke, and `#160` administrative blocker finalize.

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
