# Contract transition replay — 2026-09-03

## Question

How often did the Plan 0063 path heuristic correspond to an actual byte-level change in the public contract surface, and what coordination surface does the Plan 0064 fail-closed lock protocol impose on those historical transitions?

## Protocol authority

Pre-registered protocol: `docs/exec-plans/completed/0065-contract-transition-replay.md` (opened under `active/` before execution).

Frozen population: the same 13 cross-boundary commits from Plans 0062/0063. No post-result sampling.

Contract surface: `modules/**/.Contracts/**` plus `main/BomPraTi/Controllers/**`.

Identity: deterministic SHA-256 over path + file bytes for the parent and commit trees.

## Execution

Workflow: `BPT2 Contract Transition Replay`

Run: `33818750711`

Exact executed head: `e56fc6a3b6ce0ac66cbbfecc1de78c540630f698`

Artifact id: `9917474558`

Artifact SHA-256: `a39e2bf07b2537e47beaec10cb5b38b0b309a9fc1da2b5c762dd533c4b5ea75a`

## Results

| Metric | Result |
| --- | ---: |
| Historical cross-boundary commits | 13 |
| Contract-sync candidates by Plan 0063 heuristic | 12/13 (92.31%) |
| Actual contract fingerprint changes among candidates | 12/12 (100%) |
| Heuristic false positives for byte-level contract drift | 0 |
| Stale-lock cases if backend integrated first | 12/12 |
| Compatible-scenario checkpoints | 48 total (4 per real transition) |
| Breaking-scenario checkpoints | 72 total (6 per real transition) |

The single non-candidate was `688157b93f046c3850ddd169449b9b1fa94b1848`: it had a frontend client signal but no backend contract signal and its contract fingerprint did not change.

Across the 12 actual contract transitions, the number of directly changed contract-surface paths per commit was: 1, 3, 4, 2, 1, 3, 1, 3, 3, 2, 1, 1.

## Interpretation against pre-declared rules

`actual_contract_changes / contract_sync_candidates = 1.00`, so the `< 0.50` invalidation threshold did not fire. For this frozen historical population, the Plan 0063 path heuristic had no false positive for byte-level drift.

`stale_lock_cases = 12 > 0`, so a two-repository design preserving the current contract boundary needs an explicit synchronization mechanism equivalent in purpose to the experimental lock, or evidence for an alternative mechanism, before a split recommendation is admissible.

This result strengthens only the claim that cross-boundary BPT2 changes in the measured period frequently required simultaneous contract/client evolution. It does not classify those transitions as semantically compatible or breaking.

## Checkpoint model

The compatible scenario counts four observable checkpoints per real transition: backend integrate/publish, backend availability, frontend lock/integration, frontend availability.

The breaking scenario counts six: introduce dual-support, deploy dual-support, integrate/update frontend, deploy frontend, remove old backend support, deploy cleanup.

These counts are a protocol state model, not elapsed time, human effort, PR review time, or maintenance cost.

## Limitations

- Byte changes do not imply breaking API changes.
- The path-defined surface may include files whose externally observable behavior did not change.
- Other semantic coupling outside the defined surface is not measured.
- Historical results do not guarantee future frequencies.
- No real package registry, two-repository deployment, rollback duration, or developer lead time was measured.

## Consequence for architecture study

Build isolation is demonstrated by Plan 0064, while this replay demonstrates that all 12 historical contract-sync candidates also changed the contract fingerprint. Therefore the next decision-relevant evidence, if the monorepo-vs-split question is to be closed, must measure an operational quantity not yet measured — e.g. real two-stream CI/deploy/rollback lead time or a controlled maintenance workload — rather than repeat build-isolation or path-coupling tests.
