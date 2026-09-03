# Monorepo coupling baseline — 2026-09-03

## Question

What does the current unified BPT2 repository show about recent backend/frontend co-change, direct file coupling, and PR workflow path scoping before any recommendation about monorepo versus split repositories?

## Protocol authority

Pre-registered protocol: `docs/exec-plans/completed/0062-monorepo-coupling-baseline.md` (originally created under `active/` before execution).

The protocol fixed a 100-commit first-parent window, path classifications, metrics, next-experiment thresholds, environment and threats to validity before results were observed.

## Exact-head execution

Workflow: `BPT2 Monorepo Coupling Baseline`

Run: `33762990004`

Measured PR head: `8a98ca748647f91f50e018c7e0c63bd44e64b430`

Runner: GitHub Actions `ubuntu-24.04`

Artifact: `monorepo-coupling-baseline`, artifact id `9896272092`, SHA-256 digest `4799ff71c09b68aeb3a4e51da0d073f8a2a9ab7002e816932de7b37eb256577d`.

## Results

| Metric | Result |
| --- | ---: |
| First-parent commits examined | 100 |
| Product commits in denominator | 45 |
| Backend-only | 25 (55.56%) |
| Frontend-only | 8 (17.78%) |
| Cross-boundary | 12 (26.67%) |
| Direct file/path references crossing frontend/backend | 0 |
| PR workflows measured | 28 |
| Frontend-scoped workflows | 11 |
| Backend-scoped workflows | 24 |
| Dual-scoped workflows | 10 |
| PR workflows without `paths` | 0 |

## Interpretation against the pre-declared rule

`product_commits_n = 45`, so the minimum sample condition (`>= 30`) is satisfied for this bounded frequency observation.

`direct_cross_boundary_reference_count = 0`, so this static check did not find a direct file/import dependency that must be removed before a split experiment. This does **not** mean the frontend/backend are semantically independent; API contracts remain an integration boundary.

`cross_boundary_ratio = 26.67%`, which is above the pre-declared `>= 25%` threshold. Therefore the next comparative study must explicitly include the cost of coordination and atomicity for changes that would span repositories if frontend and backend were separated.

The workflow configuration also shows declared path selection is present: no measured PR workflow lacks a `paths` filter. Ten workflows are dual-scoped, so a later CI-cost experiment should distinguish necessary cross-boundary gates from broad path overlap rather than treating all CI as indivisible.

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
