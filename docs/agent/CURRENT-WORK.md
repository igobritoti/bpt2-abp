# Current work

Last verified: **2026-09-03**

Snapshot volatile only.

## In flight

- Wave `PRODUCT-WAVE-LISTING-DECISION-SUPPORT-01`: public Listing detail decision support using canonical vehicle facts and current public actions.
- The product slice and its remote runtime validation are integrated into `origin/main`.
- Public Listing decision-support patch is in place:
  - public Listing detail preserves safe return navigation;
  - public Listing detail reinforces canonical vehicle identity with brand/model/generation/version/model year plus available opaque technical fields from the catalog;
  - public Listing detail links explicitly to the Vehicle Hub as the canonical vehicle authority;
  - public Seller context remains authorized and public-only.
- Validation evidence for this slice:
  - `npm run lint`, `npm run typecheck`, and `npm run build` passed for `public-web` during the product slice;
  - PR #185 added the `BPT2 Listing Decision Support Runtime Gate` and its exact-head run `33761113685` passed on `66fb58623ef9b8fb2ee8f81b414dd885957bb3ad`;
  - that run used PostgreSQL 17, applied a fresh database, seeded host/OpenIddict data and a canonical Vehicle fixture, built and started the production `public-web`, exercised a real published Listing through the API, and validated the server-rendered Listing detail over HTTP;
  - rendered evidence covered the canonical-vehicle section, Vehicle Hub link, safe internal `returnTo`, and rejection of an external `returnTo` target.
- Scope limit: this is real PostgreSQL + API + production Next.js SSR/HTTP validation. It is not browser-engine automation and does not claim client-side hydration or interactive-browser coverage.
- Remote integration state:
  - `main` includes the persistent runtime gate via PR #185 at `c692450a1cc7c45de7b7b5bf1723926d88aa481a`.
- Current control-plane artifacts:
  - [docs/baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md](../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md)
  - [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md)

## Blocker register

| ID | Blocker | Affects | Evidence | Required unblock | Can wave continue? |
| --- | --- | --- | --- | --- | --- |
| BR-01 | Resolved for the defined remote SSR/HTTP runtime validation | Listing decision-support runtime smoke | PR #185 exact-head run `33761113685` passed with PostgreSQL 17 + real API + production `public-web` SSR | None for the measured SSR/HTTP acceptance boundary; browser-engine coverage would require a separately defined acceptance target | yes |
| BR-02 | `#160` main-branch integration policy remains administrative | repository administration | open issue #160; 2026-09-03 verification still reports `main` unprotected and no repository ruleset | repository administration authority | yes |

## Immediate blocker

No repo-internal or defined Listing decision-support runtime blocker remains. The remaining registered boundary is repository administration in #160.

## Remote integration state

- remote repository remains `tihotm/bpt2-abp`;
- `main` includes the Listing decision-support product slice and its reproducible runtime gate.

## Next closure item

Treat `PRODUCT-WAVE-LISTING-DECISION-SUPPORT-01` as complete for its currently defined product and SSR/HTTP runtime acceptance. Keep #160 separate as an administrative repository-control item.

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
