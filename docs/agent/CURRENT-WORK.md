# Current work

Last verified: **2026-08-31**

Snapshot volatile only.

## In flight

- Wave `PRODUCT-WAVE-LISTING-DECISION-SUPPORT-01`: public Listing detail decision support using canonical vehicle facts and current public actions.
- The wave is integrated into `origin/main` at `ef81ed9cd5673617336ffa172454eeb1dd42a57e`.
- Public Listing decision-support patch is in place:
  - public Listing detail preserves safe return navigation;
  - public Listing detail now reinforces canonical vehicle identity with brand/model/generation/version/model year plus available opaque technical fields from the catalog;
  - public Listing detail links explicitly to the Vehicle Hub as the canonical vehicle authority;
  - public Seller context remains authorized and public-only.
- Repo-internal validation that passed on this slice:
  - `npm run lint` in `public-web`;
  - `npm run typecheck` in `public-web`;
  - `npm run build` in `public-web` with `BPT_PUBLIC_BASE_URL` and `BPT_API_BASE_URL` defined.
- Remote integration state:
  - `main` now includes the Listing decision-support patch at `ef81ed9cd5673617336ffa172454eeb1dd42a57e`.
- Current control-plane artifacts:
  - [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
  - [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)

## Blocker register

| ID | Blocker | Affects | Evidence | Required unblock | Can wave continue? |
| --- | --- | --- | --- | --- | --- |
| BR-01 | Browser/DB runtime unavailable on this machine | end-to-end Listing decision-support smoke | `BPT_DB_CONNECTION`, `BPT_FIXTURE_VEHICLE_ID`, and `BPT_PUBLIC_BASE_URL` are absent on this machine | PostgreSQL-capable runtime / browser smoke env | yes |
| BR-02 | `#160` main-branch integration policy remains administrative | repository administration | open issue #160 and branch-protection/ruleset enforcement remain unresolved | repository administration authority | yes |

## Immediate blocker

Repo-internal work is integrated locally. Remaining validation is external: browser/DB smoke and repository administration.

## Remote integration state

- remote repository remains `tihotm/bpt2-abp`;
- current worktree/branch contains the integrated Listing decision-support patch.

## Next closure item

Keep the current wave in `COMPLETE_EXTERNAL_VALIDATION_PENDING` while the remaining browser/DB smoke and `#160` administrative blocker finalize.

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
