# ADR-0011: Podium 7 catalog integration boundary

Status: **Accepted for bounded-context/contract boundary; repository topology DEFERRED**

Date: 2026-08-25

## Context

`BomPraTi.Catalog` remains the sole authority allowed to mutate the catalog published and referenced by the marketplace (ADR-0001). Podium 7 is the automotive knowledge producer for evidence acquisition, provenance, normalization, conservative entity resolution, review, canonical knowledge persistence and export.

Podium 7 already exposes a frozen Catalog JSON Contract `2.0` with stable opaque IDs and `redirectsFrom`. Its Catalog Identity V2 is richer than the current BPT2 `Vehicle` model and can represent structured variant/powertrain/transmission/body style/market plus separate manufacture/model-year ranges.

A structural test proved that a single Podium entity can require multiple BPT2 `Vehicle` publication rows when a model-year range spans more than one year. A deterministic projection experiment also proved replay idempotency, stable-ID correction, redirect handling, offline BPT2 publication state and—critically—that identical labels under different Podium IDs do not need to be resolved again by BPT2.

The owner subsequently clarified that repository/language consolidation is a medium/long-term maintenance decision and does not need to block the broader BPT2 product audit (Comparator, moderation, persistence and other roadmap work). Therefore repository placement and language convergence must not be frozen by the first integration experiment.

## Accepted decision — semantic/operational boundary

Authority is split by concern:

- Podium 7 owns source acquisition, raw evidence/provenance, normalization, entity resolution and unresolved identity review within its knowledge-integration bounded context.
- `BomPraTi.Catalog` owns publication policy, BPT2 catalog persistence and the IDs referenced by marketplace Listings.
- The integration adapter consumes a frozen/versioned Podium public contract only. It must not access Podium persistence or reproduce Podium label/entity-resolution logic.
- Podium stable IDs and historical redirects are external identities for the BPT2 projection; they are not assumed to be identical to BPT2 `VehicleId` values.
- A Podium identity may project to zero, one or many BPT2 publication rows. This cardinality must be represented explicitly rather than hidden by string concatenation or arbitrary year selection.
- The marketplace public read path must not require live acquisition/resolution from Podium.

These rules remain valid whether the code later lives in two repositories, one polyglot monorepo, or one predominantly .NET monorepo.

## Deferred decision — repository and language topology

The following are explicitly **not decided yet**:

1. keep BPT2 and Podium in separate repositories;
2. move both into one polyglot monorepo while preserving Python + .NET runtimes;
3. move into one monorepo and progressively port selected Podium modules to .NET;
4. full language/runtime convergence.

A prior conclusion that separate repositories were the final topology is superseded by this narrower ADR. The current evidence proves the bounded-context and contract boundary, not the optimal Git repository count.

## Evidence class

- **A**: Podium frozen JSON/consumer contracts; BPT2 current Catalog contracts; GitHub Actions native path filtering; current architecture guidance on data ownership/shared-schema coupling.
- **B**: executable projection experiment for replay, correction, 1:N model-year materialization, no label re-resolution, redirects and offline publication state.
- **C**: repository topology can be deferred without weakening the semantic boundary because neither Comparator nor current marketplace reads require Podium to be colocated or online.
- **D**: any claim that one repository or one language will necessarily reduce total maintenance remains a hypothesis until measured against actual coordination and migration costs.

## Consequences

- BPT2 may continue product work without first moving or rewriting Podium.
- A future monorepo experiment must preserve path-selective CI so unrelated Python/.NET suites do not run unnecessarily.
- Any Python→.NET port must use Podium's existing contracts, benchmarks and behavioral tests as golden-master parity gates; translation by syntax alone is insufficient.
- No shared database follows from a monorepo decision; data/model ownership remains explicit.
- Contract-breaking Podium changes still require a new contract version and explicit BPT2 adaptation.

## Revisit triggers

Actively revisit repository/language topology when at least one of these becomes true:

- cross-repository contract changes become frequent enough to cause measurable coordination/release overhead;
- BPT2 needs multiple Podium capabilities in the same development slice repeatedly;
- duplicate CI/harness/documentation maintenance becomes material;
- a .NET parity prototype passes the relevant Podium golden tests/benchmarks with acceptable implementation complexity;
- Python runtime/dependency/operations become a material production burden;
- a shared transactional invariant emerges that changes the bounded-context assumptions.

Do **not** revisit merely because more product work exists elsewhere; the topology decision is intentionally secondary until evidence makes it consequential.
