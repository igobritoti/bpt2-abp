# Multi-repo contract-boundary prototype — 2026-09-03

## Scope

Controlled prototype selected by Plans 0062/0063. No permanent repository split and no product/runtime/schema/dependency change.

## Frozen source

`main` before experiment: `1006d6c1f1e61942b037487bf1fbc9cd86d3b6ba`.

## Execution

- PR: #189
- workflow run: `33815473792`
- executed head: `573afbb1bdf913b71c5442d9c87e60dd5278700d`
- artifact id: `9916388576`
- artifact SHA-256: `f5d5d1d536c95d3266a551eb70195a5ef668709afbc8fd9c8ad3421c2b1e0bb4`

## Measured result

| Metric | Result |
| --- | ---: |
| Tracked files | 527 |
| Backend-product files | 255 |
| Frontend files | 40 |
| Shared/control-plane files | 232 |
| Shared files copied into frontend snapshot | 0 |
| Contract-surface files | 72 |
| Backend isolated build | PASS |
| Frontend isolated `npm ci` | PASS |
| Frontend isolated lint/typecheck/build | PASS |
| Stale contract lock rejected | PASS |
| Updated contract lock accepted | PASS |

Contract digest: `4bd1205c1ebf604928d2526761eba54f7e8dfc899ca6815f5d815b69dcd641d8`.

## Rollout protocol result

- unchanged contract: independent deploy mechanically permitted;
- explicitly classified compatible transition: backend publish/deploy, frontend lock update, frontend deploy;
- breaking transition: direct deploy blocked; dual-support or coordinated rollout required;
- unknown compatibility: blocked.

The prototype does not infer compatible/breaking from source changes.

## Interpretation boundary

The current BPT2 backend and `public-web` can be physically separated for build without source-file duplication into the frontend snapshot. A deterministic contract fingerprint can detect stale lock state.

This does **not** establish that two repositories are cheaper, faster, safer, or easier to maintain. It also does not negate the coordination evidence from Plan 0063: the historical workload contained frequent cross-boundary changes and high contract-sync incidence.

No recommendation to migrate repositories or adopt Nx/Turborepo follows from this experiment alone.

## Harness note

The first Harness run on the experimental head failed only because the active plan omitted repository-required `Progress log`/`Decision log` sections and generated facts had not yet incorporated the newly added workflow/active plan. The prototype workflow itself completed successfully. Those governance-only issues are corrected in the final PR head before merge consideration.
