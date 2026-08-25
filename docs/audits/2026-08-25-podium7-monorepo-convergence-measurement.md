# Podium 7 ↔ BPT2 — monorepo and .NET convergence measurement

Date: 2026-08-25

Status: **measurement; no migration authorized**

## Decision question

Should BPT2 and Podium 7 be colocated now, and should Podium progressively converge from Python to .NET?

This document separates three independent decisions:

1. **repository topology** — two repos vs one repo;
2. **language topology** — Python + .NET vs predominantly .NET;
3. **runtime/domain topology** — bounded contexts/processes/data ownership.

The third is already decided by ADR-0011: Podium knowledge acquisition/resolution and BPT2 catalog publication remain separate responsibilities regardless of repository/language.

## Current measured shape

### BPT2

- repository reported size: about 1022 KB;
- implementation baseline: .NET 10 / ABP, plus public web frontend;
- 20 GitHub workflow files currently generated/declared by repository facts;
- broad HTTP/migration gates already support path-scoped triggering.

### Podium 7

- repository reported size: about 971 KB;
- Python package requires Python >=3.11;
- optional PBEV dependency is `pdfplumber`;
- one GitHub workflow (`sequential-tests.yml`) with two validation jobs:
  - Python 3.13;
  - minimum supported Python 3.11;
- each job validates harness/runtime and executes discovered unittest tests; the main job also builds/installs the package and writes machine-readable evidence;
- tests are discovered dynamically and run **one by one**, failing on the first failed test and recording exact test identity;
- repository contains many behavior-focused test files spanning catalog identity, normalization, persistence, review, ingestion, acquisition and production-quality benchmarks.

The repository sizes are small enough that Git storage size is not currently a meaningful argument for or against monorepo.

## Test 1 — polyglot monorepo CI feasibility

### Hypothesis

Putting Python and .NET in one repository would force both full test suites to execute for every change.

### Result

**REPROVADA.**

GitHub Actions supports native `paths` / `paths-ignore` filtering for `push` and `pull_request`. Therefore a monorepo can retain independent CI surfaces such as:

```text
knowledge/podium/**      -> Podium Python gates
modules/**, main/**      -> BPT2 .NET gates
contracts/catalog/**     -> BOTH sides + contract parity gates
docs/shared/**           -> harness/docs gates only as applicable
```

The existing BPT2 repository already uses path-triggered workflows, so this is compatible with current operating style.

### Residual risk

Required checks must be designed carefully because GitHub documents that path-filtered workflows that are required but skipped can remain pending. A monorepo migration therefore needs a required-check strategy (for example a lightweight always-running change-classifier/aggregate gate), not merely copying all current `paths` filters blindly.

## Test 2 — repository consolidation cost

Repository consolidation itself does **not** require translating Podium behavior.

Minimum work classes:

1. preserve Podium Git history or import a snapshot with explicit provenance decision;
2. choose root layout and ownership conventions;
3. merge root harness/docs without losing Podium's invariants;
4. move Python workflow under path filtering;
5. update relative paths/package installation;
6. add shared contract gate;
7. prove BPT-only changes do not invoke expensive Podium tests unnecessarily;
8. prove Podium-only changes do not invoke BPT HTTP/database suite unnecessarily;
9. prove contract changes invoke both.

This is primarily repository/CI engineering. It does **not** require rewriting acquisition, resolver, evidence, review or persistence.

### Current classification

**LOWER technical risk than language convergence, but no current product blocker requires it.**

## Test 3 — progressive Python → .NET convergence cost

A trustworthy port cannot be estimated as "number of Python files to translate". Podium's valuable asset is its behavior and evidence contract. Each migrated capability must therefore pass parity against the Python implementation and/or frozen expected datasets before Python can be retired for that capability.

### Required parity families

| migration unit | evidence that must be repeated in .NET before retirement | relative risk |
|---|---|---|
| JSON Catalog Contract `2.0` | exact keys/types/nullability/redirect behavior/unsupported-version behavior | low |
| consumer lookup/pagination | canonical vs historical IDs, error codes, keyset pagination | low-medium |
| normalization primitives | frozen input/output values, units, text normalization | medium |
| Catalog Identity model | invariants, separate manufacture/model years, external identifier semantics | medium |
| entity resolver | golden benchmark, BR benchmark, year-semantic cases, hard negatives, partial-label contradictions, MATCH/NO_MATCH/REVIEW parity | **very high** |
| stable IDs + redirects | creation/correction/merge/chained redirects | high |
| evidence/provenance/fusion | immutable evidence semantics, conflicts, no silent confidence winner | high |
| persistence | schema/version semantics, semantic integrity, replay | high |
| batch ingestion | idempotency, resolver integration, conflict/review routing | high |
| review queue/operator | durable REVIEW behavior, audited mutation, evidence binding | high |
| PBEV/document extraction | source-specific parsing/fixtures and acquisition behavior | medium-high |
| HTTP/network acquisition | allow/deny policy, bound targets, source policy, regression corpus | high |
| production corpus/quality gates | end-to-end replay and measured identity/review outcomes | **very high** |

### Rule

A .NET module is not a replacement merely because its unit tests are green. Retirement of the Python equivalent requires the relevant **behavioral and benchmark parity gates** to be green on the same frozen fixtures/corpora.

## Test 4 — what can be ported cheaply first?

The existing shape suggests this sequence if convergence is later selected:

1. **wire contracts / DTO serialization** — deterministic and low ambiguity;
2. **pure normalization primitives** — mostly deterministic input/output;
3. **catalog identity value model** — with year/external-ID invariants;
4. **consumer API semantics**;
5. **resolver** only after all benchmark datasets are made language-neutral;
6. **persistence/review/ingestion** after resolver parity;
7. **acquisition/extraction** last, and only if .NET produces a real maintenance/operational advantage.

Acquisition is the strongest candidate to remain Python even in a predominantly .NET future because document/data tooling may retain a practical ecosystem advantage. This is a hypothesis to measure later, not a permanent rule.

## Test 5 — cost of delaying the monorepo decision

### What breaks if we do nothing now?

Currently, nothing in the next BPT2 product investigations requires repository colocation:

- Comparator remains a BPT2 product capability consuming published catalog/enrichment;
- moderation is inside BPT2 marketplace authority;
- persistence/database decisions can proceed inside BPT2 bounded contexts;
- Podium already has a versioned consumer/export contract;
- BPT2 public reads must not require Podium online regardless of repo layout.

### Delay cost currently observed

- contract changes still require coordination across two repos;
- duplicate root governance/harness/issue tracking continues;
- cross-repo agent context switching remains.

No measured frequency/cost of these problems exists yet.

### Delay benefit

By postponing topology migration we can observe actual coupling while the BPT2 roadmap develops. Comparator/enrichment work may reveal whether Podium and BPT2 contracts change together frequently enough to justify monorepo, instead of migrating based on predicted future pain.

## Value-of-information conclusion

The repository decision currently has **low urgency** because:

1. semantic ownership is already protected by a versioned boundary;
2. no immediate product slice requires source colocation;
3. monorepo can be introduced later without first changing language/runtime;
4. converting Podium to .NET has much higher behavioral risk than simply colocating repos;
5. future Comparator/enrichment work will generate better evidence about coordination frequency and which Podium fields BPT2 truly needs.

Therefore deciding topology now would consume engineering attention while providing little additional information to Comparator/moderation/database decisions.

## Recommendation

### Now

**Do not migrate repositories and do not port Podium.**

Treat Podium as the already-existing catalog knowledge producer and continue BPT2 product audit/implementation work.

Preserve:

- Podium JSON contract `2.0` as external boundary;
- projection experiment in BPT2;
- ADR-0011 bounded-context ownership;
- topology as explicitly deferred.

### Measure while continuing product work

Record these counters qualitatively/quantitatively as real work happens:

1. number of slices requiring simultaneous changes in both repos;
2. number of contract-version/adaptation changes;
3. duplicated CI/harness fixes performed in both repos;
4. defects caused by producer/consumer version skew;
5. time/steps spent coordinating cross-repo release (when real releases exist);
6. Python-specific operational burden, if any;
7. .NET features repeatedly duplicating Podium semantics.

### Revisit threshold

Open a dedicated monorepo/convergence slice when repeated evidence shows coordination overhead is material, or when a concrete BPT2 feature requires enough shared evolution that one atomic PR would clearly reduce risk.

If that happens, first perform **polyglot monorepo colocation with zero behavioral rewrite**. Only after that should Python→.NET convergence be evaluated one migration unit at a time.

## Current decision table

| question | status |
|---|---|
| Podium feeds BPT2 catalog | **DECIDIDO** |
| Podium owns acquisition/evidence/resolution | **DECIDIDO** |
| BPT2 owns marketplace publication | **DECIDIDO** |
| shared database | **NÃO** under current evidence |
| synchronous Podium dependency in public request path | **NÃO** under current evidence |
| one repo now | **ADIADO** |
| polyglot monorepo technically feasible | **PASSA** |
| full Python→.NET rewrite now | **NÃO RECOMENDADO** |
| progressive .NET convergence later | **CANDIDATO, via parity** |
| Comparator/moderação/database blocked by topology | **NÃO** |
