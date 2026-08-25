# ADR-0011: Integrate Podium 7 through an asynchronous versioned catalog contract

Status: Accepted

Date: 2026-08-25

## Context

`BomPraTi.Catalog` remains the sole authority allowed to mutate the catalog published and referenced by the marketplace (ADR-0001). Podium 7 is a separate Python product for automotive evidence acquisition, provenance, normalization, conservative entity resolution, review, canonical knowledge persistence and export.

Podium 7 already exposes a frozen Catalog JSON Contract `2.0` with stable opaque IDs and `redirectsFrom`. Its Catalog Identity V2 is richer than the current BPT2 `Vehicle` model and can represent structured variant/powertrain/transmission/body style/market plus separate manufacture/model-year ranges.

A structural test proved that a single Podium entity can require multiple BPT2 `Vehicle` publication rows when a model-year range spans more than one year. A deterministic projection experiment also proved replay idempotency, stable-ID correction, redirect handling, offline BPT2 publication state and—critically—that identical labels under different Podium IDs do not need to be resolved again by BPT2.

## Decision

Keep Podium 7 and BPT2 as separate repositories/projects and integrate them initially through an **asynchronous, frozen, versioned export/import contract**.

Authority is split by concern:

- Podium 7 owns source acquisition, raw evidence/provenance, normalization, entity resolution and unresolved identity review within its knowledge-integration context.
- `BomPraTi.Catalog` owns publication policy, BPT2 catalog persistence and the IDs referenced by marketplace Listings.
- The integration adapter consumes the Podium public contract only. It must not access Podium persistence or reproduce Podium label/entity-resolution logic.
- Podium stable IDs and historical redirects are external identities for the BPT2 projection; they are not assumed to be identical to BPT2 `VehicleId` values.
- A Podium identity may project to zero, one or many BPT2 publication rows. This cardinality must be represented explicitly rather than hidden by string concatenation or arbitrary year selection.

The first integration must not introduce a shared database, monorepo migration, queue or synchronous HTTP/RPC dependency unless a measured requirement later proves the simpler contract/batch boundary insufficient.

## Evidence class

- **A**: Podium frozen JSON/consumer contracts; BPT2 current Catalog contracts; current Microsoft architecture guidance on service data ownership and avoiding shared schemas.
- **B**: executable projection experiment for replay, correction, 1:N model-year materialization, no label re-resolution, redirects and offline publication state.
- **C**: separate repositories + asynchronous contract is the lowest-coupling option satisfying the observed requirements.

## Consequences

- BPT2 remains available for marketplace reads when Podium is offline.
- Podium can change internal acquisition/resolution implementation without forcing a BPT2 deploy while contract `2.0` remains compatible.
- BPT2 needs explicit persistence for Podium external identity, redirects/supersession and publication mapping before production import.
- Rich Podium fields must not be silently discarded if they are needed for future enrichment/comparison; the publication/projection model must preserve or intentionally classify them.
- Contract-breaking Podium changes require a new contract version and explicit BPT2 adaptation.
- Full runtime unification is rejected with current evidence; same-repository placement has no demonstrated benefit; synchronous service transport remains deferred.

## Revisit triggers

Reopen this ADR if evidence shows any of the following:

- BPT2 requires strong synchronous consistency with Podium on a user request path;
- batch/export latency fails a measured product requirement;
- the adapter necessarily reimplements entity resolution rather than deterministic projection;
- repository separation causes measured coordination/deploy cost greater than the semantic/toolchain independence it preserves;
- a shared transactional invariant emerges that cannot be satisfied safely across the boundary.
