# Podium quantitative consumer benchmark — 2026-08-29

Issue: #122

Status: **CONSUMER SHAPE/STATE/COMPARABILITY BOUNDARY PROVED ON BOUNDED CONTRACT FIXTURE; COMPARATOR PRODUCT READINESS NOT PROVED**

## Authority and reproducibility

The benchmark consumes the published producer boundary, not Podium persistence or acquisition internals.

- producer repo: `gestbrito/podium7`
- pinned producer commit: `fad13769cbdc79fea7d87b9a9bebca3a41240557`
- producer schema: `podium7.quantitative-enrichment.v1`
- authority doc: `docs/QUANTITATIVE-ENRICHMENT-CONSUMER-CONTRACT-V1.md`
- producer implementation checked: `podium7/enrichment_contract.py`
- producer focused tests checked: `tests/test_enrichment_contract.py`
- BPT2 fixture: `benchmarks/podium_quantitative_consumer_v1.json`
- BPT2 fixture SHA-256: `a7a0012a83488a73d7d73989348c3ba3fe4a34751276a56c490da4d4691167f8`
- GitHub Actions run: `33282078314`
- artifact id: `9723278865`
- artifact ZIP digest: `sha256:2d49bd31df9d4b63cd44fbb78d85bbe3f303e59f7b64299aab983f07efd33165`

This fixture is bounded contract evidence. It is not a claim of production-wide or Brazil-market coverage.

## Contract acceptance

Executed result:

- accepted producer-compatible payloads: **15/15**;
- rejected negative controls: **2/2**;
- raw envelope lossless round trips: **15/15**;
- strict typed projection lossless round trips: **15/15**;
- compiler: zero warnings / zero errors on .NET 10.

The strict consumer validates exact schema and field vocabulary, knowledge state, value shape, quantitative units, material context, conflicts, duplicate/overlap constraints represented by the producer boundary, and the producer SHA-256 semantic revision. Unsupported schema and unsupported field fail closed.

## Evidence classes preserved

The fixture deliberately distinguishes producer evidence classes.

### Evidence-backed / retained

- `power` scalar correction/revision behavior from the producer contract test;
- explicit `torque = unknown` behavior from the producer contract test;
- unresolved `power` conflict behavior from the producer contract test;
- retained `curb_weight` range `1490–1508 kg` bound to producer provenance `git:blob:514ba9e738607376551f71e7f650af42686e68ea`.

### Contract-shape-only

The following are exercised only to prove the consumer can preserve/fail closed on shapes the V1 contract permits:

- `limit`;
- `multiple`;
- `not_applicable`;
- material context;
- supporting synthetic same-unit scalar/range values used solely by the comparison oracle.

These cases are not converted into claims that retained publication-ready product evidence exists for those shapes.

## Identity boundary

The benchmark pins canonical `podium7:vehicle:1` and historical `podium7:vehicle:old-1` to the same BPT2 `VehicleId` and proves convergence before quantitative consumption.

`quantitativeFactsUsedForIdentityResolution = false`.

This matches the existing Podium Catalog feed boundary: external canonical/redirect identities resolve to one BPT2 Vehicle first; quantitative facts cannot rematch or split that identity.

## Current-state semantics

The executed state sequence passed:

1. first `power=169 hp` revision → `CREATED`;
2. identical revision replay → `REPLAY_NO_CHANGE`;
3. corrected `power=170 hp`, same VehicleId/new revision → `REPLACED`;
4. unresolved `power` conflict revision → `REPLACED`.

Final state contains no canonical `power` fact and does contain the unresolved conflict. The benchmark therefore does not preserve a stale winner after the producer moves to fail-closed conflict state.

## Comparability baseline

All **12/12** fixed comparison cases matched the conservative oracle.

Proved on this bounded fixture:

- same-unit scalar `169 hp < 170 hp`;
- identical scalar replay = equal;
- range `1490–1508 kg < 1520 kg` when disjoint;
- scalar `1500 kg` inside retained range → `NOT_ORDERABLE`;
- range `1490–1508 kg < 1510–1520 kg` when disjoint;
- context mismatch → `NOT_COMPARABLE`;
- `unknown` versus known → `NOT_COMPARABLE`;
- `not_applicable` versus known → `NOT_COMPARABLE`;
- limit versus scalar → `NOT_COMPARABLE`;
- multiple versus scalar → `NOT_COMPARABLE`;
- `kW` versus `hp` → `NOT_COMPARABLE`; no unit conversion is inferred;
- unresolved conflict versus known → `NOT_COMPARABLE`.

No winner is fabricated from overlap, missingness, unresolved conflict, incompatible context, or merely convertible-looking units.

## Projection decision

The benchmark demonstrates that a BPT2 consumer can preserve the V1 envelope semantics without flattening:

- `knowledgeState`;
- scalar/range/limit/multiple shape;
- raw unit;
- material context;
- producer revision;
- provenance;
- unresolved conflict.

Both an opaque/raw envelope projection and a strict typed projection achieved zero semantic-loss cases in the fixed fixture. This does **not** select a production persistence schema. Schema choice should occur only with a concrete Vehicle Hub/Comparator slice and coverage evidence.

## What remains blocked

The benchmark does not prove production or Brazil coverage. Consequently:

`BPT2_QUANTITATIVE_CONSUMER_SHAPE_READINESS = PROVED_BOUNDED`

`CONSUMER_SEMANTIC_LOSS_ON_FIXED_FIXTURE = 0`

`SAME_UNIT_SCALAR_RANGE_COMPARABILITY = PROVED_BOUNDED`

`UNIT_CONVERSION = NOT_AUTHORIZED`

`CONTEXT_MISMATCH = NOT_COMPARABLE`

`LIMIT_MULTIPLE_ORDERING = NOT_AUTHORIZED`

`PRODUCT_READY_QUANTITATIVE_FIELDS = NONE`

`COMPARATOR_UI = STILL_BLOCKED`

`PBEV_BR_COVERAGE = STILL_UPSTREAM_GATED`

The next promotion decision requires evidence-backed usable coverage for the intended Brazil product slice and field-specific comparability semantics. The presence of a stable producer contract and a lossless consumer is necessary but not sufficient for Comparator product readiness.
