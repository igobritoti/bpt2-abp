# Monorepo coupling baseline — 2026-09-03

## Question

What does the current unified BPT2 repository show about recent backend/frontend co-change, direct file coupling, and PR workflow path scoping before any recommendation about monorepo versus split repositories?

## Protocol authority

Pre-registered protocol: `docs/exec-plans/completed/0062-monorepo-coupling-baseline.md` (originally created under `active/` before execution).

The protocol fixed baseline commit `53be795b6205ef57c03f1118e0c0287dc0f2873c`, a 100-commit first-parent window, path classifications, metrics, next-experiment thresholds, environment and threats to validity before the accepted result.

## Accepted execution

Workflow: `BPT2 Monorepo Coupling Baseline`

Run: `33763243292`

Measured PR tree head: `a74e835838b40f432bf332f448622eb7f88d068d`

Frozen history ref/SHA: `53be795b6205ef57c03f1118e0c0287dc0f2873c`

Runner: GitHub Actions `ubuntu-24.04`

Artifact: `monorepo-coupling-baseline`, artifact id `9896377668`, SHA-256 digest `246d3c6c61331b550b7a8b3d25561bcf5d9dd18c91a25fc7f8447c1a053f39f4`.

## Results

| Metric | Result |
| --- | ---: |
| First-parent commits examined | 100 |
| Product commits in denominator | 49 |
| Backend-only | 25 (51.02%) |
| Frontend-only | 11 (22.45%) |
| Cross-boundary | 13 (26.53%) |
| Direct file/path references crossing frontend/backend | 0 |
| PR workflows measured | 28 |
| Frontend-scoped workflows | 11 |
| Backend-scoped workflows | 24 |
| Dual-scoped workflows | 10 |
| PR workflows without `paths` | 0 |

## Interpretation against the pre-declared rule

`product_commits_n = 49`, so the minimum sample condition (`>= 30`) is satisfied for this bounded frequency observation.

`direct_cross_boundary_reference_count = 0`, so this static check did not find a direct file/import dependency that must be removed before a split experiment. This does **not** mean the frontend/backend are semantically independent; API contracts remain an integration boundary.

`cross_boundary_ratio = 26.53%`, which is above the pre-declared `>= 25%` threshold. Therefore the next comparative study must explicitly include the cost of coordination and atomicity for changes that would span repositories if frontend and backend were separated.

The workflow configuration also shows declared path selection is present: no measured PR workflow lacks a `paths` filter. Ten workflows are dual-scoped, so a later CI-cost experiment should distinguish necessary cross-boundary gates from broad path overlap rather than treating all CI as indivisible.

## Instrumentation corrections

The first execution was discarded because GitHub's default PR checkout measured the synthetic merge-ref instead of the PR head.

A second execution used the exact PR head but exposed a separate contamination risk: instrumentation/docs commits in the same PR shifted the moving 100-commit window. Because the protocol had already frozen `53be795...` as the baseline commit, the accepted instrument was corrected to use that frozen commit for history while using the current PR head for tree/workflow measurements. This correction aligns execution with the pre-registered context instead of changing the threshold or hypothesis after observing results.

## What this does not prove

This baseline does not prove that the current monorepo is faster, cheaper, simpler, safer or more maintainable than split repositories. It also does not prove that Nx, Turborepo or another workspace orchestrator is necessary.

Commit co-change is a proxy for coordination frequency, not developer effort or lead time. The current repository has no simultaneous equivalent split-repository control, so no causal architecture comparison was performed.

## Next experiment selected by evidence

Construct a controlled split-repository simulation or equivalent isolated-worktree experiment for a representative sample of cross-boundary changes and measure at least:

- number of commits/PRs required to preserve an atomic logical change;
- contract/version synchronization steps;
- CI invocations and wall-clock gate cost attributable to each boundary;
- failure/rollback coordination steps;
- any duplicated configuration required solely by the split.

The comparison must preserve equivalent product behavior and gates. No final architecture recommendation is admissible until that controlled comparison exists.
