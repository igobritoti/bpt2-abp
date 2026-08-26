# Podium 7 ↔ BPT2 integration boundary test

Date: 2026-08-25

## Question

Should Podium 7 and BPT2 be fully unified, kept in one repository with separate runtimes, exposed as synchronous services, or remain separate projects integrated by a versioned contract?

## Observed facts

### Podium 7

Podium 7 is a Python system whose current product responsibility is automotive knowledge acquisition, evidence persistence, normalization, conservative entity resolution, conflict/review handling, canonical knowledge persistence and export.

Catalog Identity V2 contains dimensions not present as structured BPT2 identity fields today: aliases, variant, powertrain, transmission, body style, market, separate manufacture/model-year ranges, engine identifiers and external identifiers. It preserves stable opaque IDs and redirects after merges.

A frozen JSON contract `2.0` and transport-neutral consumer API already exist. `BOM-PRATICHE-CONTRACT-V2.md` explicitly anticipates consumption by Bom Pra Ti/Bom Pratiche and says transport should be added only if a cross-process need exists.

### BPT2

BPT2 is the marketplace/product system and, by owner decision plus ADR-0001, owns the catalog that is published to and consumed by the marketplace.

The current write contract is:

- BrandName
- ModelName
- GenerationName + optional range
- VersionName
- one `ModelYear?`

`Vehicle` stores one `ModelYear?` per row. `VehicleVersion` stores a version label and model/generation linkage.

## Structural cardinality test

### Case 1 — Podium model-year range

Input Podium identity:

```text
make = A
model = B
variant = C
model_year_from = 2025
model_year_to = 2026
```

Current BPT2 can preserve that range only by one of:

1. creating two `Vehicle` rows (MY2025 and MY2026): **1:N**;
2. creating one `Vehicle` with one arbitrary year: **information loss / invalid**;
3. creating one `Vehicle` with null year: **range semantics lost**;
4. changing the BPT2 published-catalog model.

Therefore `Podium entity.id -> BPT2 VehicleId` is not a general 1:1 contract.

### Case 2 — structured variant/powertrain/transmission

Podium can distinguish these fields independently. Current BPT2 has only a `VersionName` presentation/identity label for this level.

Concatenating fields into `VersionName` may preserve display text but destroys structured semantics and creates unstable identity when formatting changes. This fails the requirement for future technical comparison/enrichment.

### Case 3 — Podium merge/redirect

Podium preserves retired IDs through `redirectsFrom`. Current BPT2 Catalog has no equivalent redirect contract.

Blind upsert by labels can therefore recreate a duplicate after a Podium merge. Integration must store Podium external identity/redirect information or otherwise define deterministic merge handling.

## Authority matrix — accepted

| Concern | Authority | Rationale |
|---|---|---|
| source acquisition | Podium 7 | existing dedicated pipeline |
| raw evidence/provenance | Podium 7 | existing evidence invariants/store |
| normalization/entity resolution | Podium 7 | benchmarked conservative resolver |
| unresolved identity review | Podium 7 | durable REVIEW behavior already exists |
| published marketplace catalog policy | BPT2 | product/system owner decision + ADR-0001 |
| marketplace availability/read path | BPT2 | must not depend on Podium being online |
| Listing → published catalog reference | BPT2 | marketplace transactional boundary |
| integration wire semantics | shared/versioned contract | both sides must contract-test it |

This matrix intentionally avoids two writers for the same concern.

## Executable contract-projection falsification test

Artifacts:

- `scripts/podium7-contract-projection-experiment.py`
- `scripts/fixtures/podium7-catalog-contract-v2-projection.json`

The fixture uses the frozen Podium `2.0` shape and deliberately includes:

1. a canonical entity spanning model years 2025–2026;
2. a correction that keeps the same Podium ID but changes variant presentation;
3. a second Podium ID with labels equal to the corrected survivor;
4. a later merge where that second ID appears in `redirectsFrom`.

The projection is forbidden to compare labels for identity. It keys only from the stable Podium ID and explicit redirects.

Observed execution on 2026-08-25:

```text
PODIUM7_CONTRACT_VERSION: PASS
PODIUM7_REPLAY_IDEMPOTENT: PASS
PODIUM7_MODEL_YEAR_1_TO_N: PASS
PODIUM7_STABLE_ID_CORRECTION: PASS
PODIUM7_NO_LABEL_RESOLUTION: PASS
PODIUM7_REDIRECT_MERGE: PASS
PODIUM7_OFFLINE_PUBLICATION_STATE: PASS
```

The important adversarial result is `PODIUM7_NO_LABEL_RESOLUTION`: two records with identical labels but different Podium IDs remain distinct until Podium itself emits an explicit merge/redirect. Therefore the BPT2 adapter does not need to become a second automotive entity resolver.

The experiment has also been added to `BPT2 Harness Gate` so contract/projection drift is mechanically rechecked in CI.

## Option comparison

### A. Separate repositories + asynchronous versioned export/import

**PASS / selected.**

Benefits:
- preserves both mature codebases and toolchains;
- Podium can evolve/acquire/reconcile without marketplace deploy;
- BPT2 serves published catalog while Podium is offline;
- contract `2.0` already exists;
- no shared database;
- allows explicit publish/approval boundary;
- executable projection does not require duplicated entity resolution.

Costs:
- requires adapter and mapping persistence;
- redirects and 1:N materialization must be persisted explicitly;
- contract compatibility must stay gated.

### B. Same repository, separate bounded contexts/runtimes

**NOT SELECTED.**

It does not solve the semantic mapping problem. It combines Python and .NET CI/repository change surface while retaining two runtimes. No measured coordination/build benefit currently offsets that cost.

### C. Full runtime/model unification

**REJECTED with current evidence.**

It would require rewrite/transplant of existing Podium evidence/resolver/benchmark behavior and still requires deciding which identity model survives. No requirement for shared ACID transaction or request-path coupling has been observed.

### D. Separate synchronous HTTP/RPC service

**DEFERRED.**

Podium's consumer adapter is transport-neutral; BPT2 does not presently need Podium online to answer marketplace reads. Adding synchronous distribution would introduce network availability, auth, retries, latency and observability obligations without a measured online requirement.

## External architecture evidence applied

Current Microsoft architecture guidance states that separate services should own their data and avoid shared schemas because shared storage forces coordinated schema changes. It also emphasizes independent deployment, avoiding chatty dependencies and explicit service boundaries. Microservices support independent evolution but add distributed-system and consistency complexity.

Applied locally, this favors an explicit bounded-context/data boundary while choosing the simplest observed transport: versioned asynchronous export/import, not a shared database or synchronous request dependency.

## Final decision

**Keep Podium 7 and BPT2 as separate repositories/projects and integrate asynchronously through a frozen, versioned catalog contract.**

Recorded in `docs/adr/0011-podium7-catalog-integration-boundary.md`.

Evidence classification:

- **A** — current Podium/BPT2 contracts and current external architecture guidance;
- **B** — executable adversarial projection experiment;
- **C** — Option A is the lowest-coupling architecture satisfying all observed requirements.

The decision does **not** claim the production adapter already exists. It decides the boundary and forbids duplicated resolver/shared database/synchronous dependency without new evidence.

## Smallest next production slice

Implement only the BPT2-side **Podium publication mapping contract/persistence** needed to represent:

- Podium canonical external ID;
- Podium historical redirect ID → canonical external ID;
- zero/one/many BPT2 `VehicleId` publication rows for one Podium identity;
- accepted contract version;
- last imported snapshot/revision identity sufficient for idempotent replay.

That slice must not yet bulk-import the catalog, add HTTP, add a queue, or duplicate Podium resolution. Its acceptance test should replay the existing fixture through real BPT2 persistence and prove the same invariants as the pure experiment.
