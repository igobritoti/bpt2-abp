# POST_MVP_OPERATIONAL_BASELINE_V1

Repository: `igobritoti/bpt2-abp`

Baseline input frozen at:

- `RECONSTRUCTION_INPUT_SHA`: `df05fff0a62b5ae52450bde3f03d6ccc6539cc21`
- `RECONSTRUCTION_INPUT_TIME`: `2026-08-30T21:23:13.9764297-03:00`
- reconstruction working checkout: `8015e7dedcc932fc56ffdfc11e702a6869ab4d4c`

This baseline records the repository as it exists now. It does not redefine product scope, architecture, licensing, or runtime behavior.

## Stage determination

Current stage: `POST_MVP_HARDENING`

Rationale:

- the core seller and buyer journeys are already proved in product authority;
- the repository has a stable modular architecture, canonical product boundaries, and reproducible CI/gate surfaces;
- open work is concentrated in post-baseline expansion, administrative dependencies, and documentation/control-plane cleanup rather than core product invention;
- local operation and hosted CI are evidenced, but production operation is not claimed.

## Authoritative document set

| Information need | Canonical authority |
| --- | --- |
| Product | [docs/PRODUCT.md](../PRODUCT.md) |
| Architecture | [ARCHITECTURE.md](../../ARCHITECTURE.md) and accepted ADRs under [docs/adr/](../adr/) |
| Requirements / capabilities | [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md) |
| Quality | [docs/QUALITY.md](../QUALITY.md) |
| Operations | [docs/LOCAL-DEVELOPMENT.md](../LOCAL-DEVELOPMENT.md) |
| Baseline | this file |
| Closure | [docs/closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md](../closure/POST_MVP_OPERATIONAL_CLOSURE_MATRIX.md) |
| Immediate work | [docs/agent/CURRENT-WORK.md](../agent/CURRENT-WORK.md) |
| Historical evidence | [docs/audits/](../audits/) |
| Decision records | [docs/adr/](../adr/) |
| Generated facts | [docs/generated/repository-facts.md](../generated/repository-facts.md) |

## Current architecture state

- The system remains a modular monolith on ABP 10.6 with PostgreSQL persistence and one business module boundary per concern.
- The public web is a decoupled Next.js client that talks to the backend over HTTP.
- Podium remains an external producer/feed boundary; the BPT2 consumes versioned contracts and does not absorb producer-side acquisition responsibilities.
- Current runtime relationships and ownership boundaries are already captured in the product and ADR set; this baseline does not restate them as new architecture.

## Capability state summary

- Core seller flows are delivered: registration/login, profile, listings, draft/edit, photos, publish/pause/archive, and owned lead handling.
- Core buyer flows are delivered: discovery, public detail, WhatsApp contact, favorites, saved searches, listing reports, and in-app history surfaces.
- Catalog and vehicle-hub authority are delivered for the current product boundary.
- Saved search runner and email delivery engineering boundaries are delivered; external activation remains a deployment dependency, not a missing engineering capability.
- Discovery typo/fuzzy expansion, recommendation experiments, market intelligence, trust/inspection, true radius, and comparator expansion remain outside the current closure baseline unless a new product decision changes that.

## Quality state summary

Relevant quality evidence is already recorded in `docs/QUALITY.md` and the audit set:

- functional suitability: proved for defined seller, buyer, discovery, catalog, lead, moderation, promotions, and saved-search scopes;
- reliability: proved for the scopes covered by the HTTP and workflow gates, including idempotent and retry-sensitive paths already documented in product authority;
- security/ownership: proved for the authenticated boundaries explicitly exercised by the gates;
- performance efficiency: only the benchmarked scopes are proven; no blanket production-performance claim is made;
- maintainability/compatibility: the modular boundaries and ABP/Next.js separation are already fixed in architecture and ADRs.

Disposition:

- `PROVED_FOR_DEFINED_SCOPE` for the published baseline scopes;
- `PARTIALLY_PROVED` for performance and scale-sensitive expansion areas;
- `NOT_EVALUATED` for any claim outside the documented baseline boundaries.

## Operational state

What is actually evidenced today:

- `LOCAL_OPERATION_PROVED`: yes, for the documented development/bootstrap flow in `docs/LOCAL-DEVELOPMENT.md`;
- `HOSTED_CI_PROVED`: yes, for the gates and workflows already recorded in `docs/QUALITY.md`, `docs/PRODUCT.md`, and the audits;
- `DEPLOYMENT_PROVED`: no, not as a current project-wide baseline claim;
- `PRODUCTION_OPERATION_PROVED`: no, not claimed here.

Current operational envelope:

- fresh checkout bootstrap, dependency restore, build, and gate execution are documented and reproducible;
- migrations and database bootstrap are explicitly handled by the local-development procedure;
- background processing exists where the product boundary requires it, but external deployment activation remains a separate concern;
- hosted CI is authoritative for the checks already recorded in the repository;
- production deployment is outside this baseline record.

## Unresolved items

The following items remain open in the repository, but they are not baseline-closure blockers:

- `#113` recommendations ground truth: `POST_BASELINE_EXPANSION`;
- `#114` market-price source authority and stable binding: `POST_BASELINE_EXPANSION` or `EXTERNAL_DEPENDENCY` if a specific licensed provider is introduced;
- `#115` vehicle-history and inspection trust contracts: `POST_BASELINE_EXPANSION` or `EXTERNAL_DEPENDENCY` if an external provider is required;
- `#116` geographic radius semantics: `POST_BASELINE_EXPANSION`;
- `#160` main integration policy enforcement: `ADMINISTRATIVE_DEPENDENCY`.

No unresolved current-state contradiction remains between product authority, current work, and the merged workflow-concurrency evidence.

## Closure gates

| Gate | Purpose | Current state |
| --- | --- | --- |
| Gate 0 | Documentary authority | PASS |
| Gate 1 | Repository hygiene | PASS |
| Gate 2 | Core product journeys | PASS |
| Gate 3 | Catalog / integration integrity | PASS |
| Gate 4 | Reliability / security | PASS for the defined baseline scope |
| Gate 5 | Operational readiness | PARTIAL |
| Gate 6 | Baseline closure | PASS for the current baseline scope |

Notes:

- Gate 5 is partial because production operation is not claimed and external activation remains separate from engineering completeness.
- Gate 6 is pass because the remaining open issues are classified as post-baseline or administrative, not current-baseline closure blockers.

## Explicit exclusions

This baseline does not add or require:

- new product scope;
- production deployment claims;
- architectural rewrites;
- radius-search implementation;
- recommendation implementation;
- market-intelligence implementation;
- trust/inspection badges;
- comparator expansion;
- new infrastructure because a document mentions it;
- automatic work selection from issue recency instead of baseline closure priority.

## Evidence references

- [docs/PRODUCT.md](../PRODUCT.md)
- [docs/QUALITY.md](../QUALITY.md)
- [docs/LOCAL-DEVELOPMENT.md](../LOCAL-DEVELOPMENT.md)
- [docs/audits/2026-08-27-unified-functional-coverage-matrix.md](../audits/2026-08-27-unified-functional-coverage-matrix.md)
- [docs/audits/2026-08-30-workflow-concurrency-probe.md](../audits/2026-08-30-workflow-concurrency-probe.md)
- [docs/generated/repository-facts.md](../generated/repository-facts.md)
