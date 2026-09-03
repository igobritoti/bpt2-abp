# Split coordination simulation — 2026-09-03

## Question

What mechanical coordination effects appear when the 13 observed cross-boundary BPT2 changes are represented as separate backend and frontend integration streams?

## Protocol authority

Pre-registered protocol: `docs/exec-plans/completed/0063-split-coordination-simulation.md` (opened under `active/` before execution).

Frozen refs:
- history population: `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- workflow configuration: `e0cb70b9307d0122541d1cf8a04686d9d044bad4`.

Population: all 13 cross-boundary changes identified by Plan 0062. No post-result sampling was used.

## Execution

Workflow: `BPT2 Split Coordination Simulation`

Run: `33764109640`

Exact PR head: `8e6ceaa1105d7a0b0bc598ea8fc2f1e5d3f51d00`

Artifact id: `9896729215`

Artifact SHA-256: `2fb82dbef676a831c3b5e63675b98337b2cd803e7ab04990400d1ee89cc11848`

## Results

| Metric | Result |
| --- | ---: |
| Cross-boundary changes | 13 |
| Monorepo minimum PR/merge transactions | 13 |
| Simulated split minimum PR/merge transactions | 26 |
| Additional PR transactions | 13 (+100%) |
| Monorepo minimum revert transactions | 13 |
| Simulated split minimum revert transactions | 26 |
| Workflow invocations, full cross-boundary changes | 338 |
| Workflow invocations, backend + frontend partitions | 387 |
| Additional workflow invocations | 49 (+14.50%) |
| Duplicated workflow invocations across partitions | 103 |
| Changes containing shared/control-plane paths | 13/13 (100%) |
| Shared/control-plane paths across the population | 46 |
| Contract/client synchronization candidates | 12/13 (92.31%) |
| PR workflows in frozen configuration | 28 |

## Interpretation against pre-declared thresholds

`extra_workflow_invocations_ratio = 14.50%`, below the pre-declared 20% threshold. Therefore this simulation does **not** by itself require the next experiment to prioritize real CI-minute cost on that criterion. Workflow counts remain a configuration proxy, not runtime cost.

`contract_sync_candidates_ratio = 92.31%`, above the pre-declared 25% threshold. Therefore any subsequent controlled multi-repo prototype must include an explicit contract/version compatibility strategy and deployment-order measurement.

`changes_with_shared_paths_ratio = 100%`, above the pre-declared 50% threshold. Therefore any subsequent controlled multi-repo prototype must declare and measure ownership/placement of shared and control-plane material instead of silently duplicating or discarding it.

The structural transaction model also maps each observed cross-boundary logical change from one minimum integration transaction to two independent transactions under the simulated split. This is not a measurement of human effort; it establishes the minimum coordination surface that a realistic split prototype must preserve or mitigate.

## Per-change inspection

All 13 expected commits were present in the artifact. Twelve satisfy the pre-declared path heuristic for simultaneous backend contract/API plus frontend client/API change. Every change contains at least one shared/control-plane path under the study classification.

The simulation recorded workflow trigger sets for the full change, backend partition and frontend partition for every commit, including duplicated intersections.

## Glob-model limitation

The simulation uses Python `fnmatch` as an approximation for the repository's current `pull_request.paths` patterns. Inspection of the frozen workflow patterns found no negative (`!`) patterns; the relevant patterns are predominantly exact paths or `/**`. One simple wildcard family (`SavedSearchEmailDelivery*.cs`) exists. This keeps the invocation-count result usable as a bounded configuration simulation, but it is not asserted to be a byte-for-byte implementation of GitHub's path-filter engine.

A real multi-repo CI experiment, if later required for architecture selection, must measure actual workflow runs rather than rely on this approximation.

## What this does not prove

This study does not prove that monorepo is faster, cheaper, simpler, safer, or more maintainable than multiple repositories. It also does not prove that split repositories are infeasible.

It does not measure developer lead time, review latency, actual CI minutes, package publication latency, deployment time, rollback duration, or incident rate. The contract signal is a path heuristic, not a semantic compatibility test.

## Next experiment selected by evidence

The next comparative prototype must model a concrete two-repository contract boundary while preserving equivalent behavior. At minimum it must predeclare and measure:

- where shared/control-plane assets live and what must be duplicated or externally owned;
- backend contract publication/versioning or another explicit compatibility mechanism;
- frontend consumption/update steps;
- deployment ordering for compatible and breaking contract changes;
- rollback/revert ordering for a cross-boundary change;
- actual build/test gates required on each side.

No final monorepo-vs-split recommendation is admissible from Plans 0062–0063 alone.
