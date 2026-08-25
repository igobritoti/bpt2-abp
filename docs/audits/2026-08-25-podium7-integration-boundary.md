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

BPT2 is the marketplace/product system and, by owner decision, owns the catalog that is published to and consumed by the marketplace.

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

## Authority matrix — proposed and testable

| Concern | Authority | Rationale |
|---|---|---|
| source acquisition | Podium 7 | existing dedicated pipeline |
| raw evidence/provenance | Podium 7 | existing evidence invariants/store |
| normalization/entity resolution | Podium 7 | benchmarked conservative resolver |
| unresolved identity review | Podium 7 | durable REVIEW behavior already exists |
| published marketplace catalog policy | BPT2 | product/system owner decision |
| marketplace availability/read path | BPT2 | must not depend on Podium being online |
| Listing → published catalog reference | BPT2 | marketplace transactional boundary |
| integration wire semantics | shared/versioned contract | both sides must contract-test it |

This matrix intentionally avoids two writers for the same concern.

## Option comparison

### A. Separate repositories + asynchronous versioned export/import

**Passes current evidence.**

Benefits:
- preserves both mature codebases and toolchains;
- Podium can evolve/acquire/reconcile without marketplace deploy;
- BPT2 serves published catalog while Podium is offline;
- contract `2.0` already exists;
- no shared database;
- allows explicit publish/approval boundary.

Costs:
- requires adapter and mapping persistence;
- requires contract compatibility tests;
- redirects and 1:N materialization must be designed.

### B. Same repository, separate bounded contexts/runtimes

**No demonstrated benefit yet.**

It does not solve the semantic mapping problem. It combines Python and .NET CI/repository change surface while retaining two runtimes. Select only if measured coordination cost across repositories becomes material.

### C. Full runtime/model unification

**Rejected with current evidence.**

It would require a rewrite or loss of existing Podium evidence/resolver/benchmark behavior and still requires deciding which identity model survives. No requirement for shared ACID transaction or request-path coupling has been observed.

### D. Separate synchronous HTTP/RPC service

**Deferred with current evidence.**

Podium's consumer adapter is transport-neutral; BPT2 does not presently need Podium online to answer marketplace reads. Adding synchronous distribution would add network availability, auth, retries, latency and observability obligations without a proven online requirement.

## External architecture evidence applied

Current Microsoft architecture guidance treats bounded context as a model boundary, not an automatic requirement for a separate distributed service. Service boundaries should avoid chatty communication and coordinated deployment. Shared schemas create coupling; independently deployed services should own their data. Microservices provide independent deployment/scaling but add distributed-system complexity.

Applied locally, this supports keeping logical/process boundaries explicit while choosing the simplest transport that satisfies measured requirements.

## Provisional decision

**Recommend Option A for the first integration slice: keep Podium 7 and BPT2 as separate repositories/projects and integrate asynchronously through a frozen versioned contract.**

Confidence: **C (strong inference from A/B evidence), not yet final**.

Do not create HTTP, queue or monorepo migration in the first slice.

## Required falsification tests before final decision

1. Build a BPT2 contract fixture consumer for Podium `2.0`.
2. Demonstrate 1:N handling for model-year ranges without losing identity/provenance.
3. Demonstrate idempotent replay of the same export.
4. Demonstrate correction with stable Podium ID.
5. Demonstrate merge with `redirectsFrom` without duplicate BPT2 publication rows.
6. Demonstrate BPT2 public reads with Podium unavailable.
7. Demonstrate a compatible Podium internal evolution that leaves `2.0` unchanged requires no BPT2 deployment.
8. If these tests fail because continuous online coordination is intrinsically required, reopen Option D or C with the observed failure as evidence.
