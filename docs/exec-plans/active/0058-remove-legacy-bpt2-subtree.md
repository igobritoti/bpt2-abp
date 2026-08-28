# Plan 0058 — Remove legacy `bpt2/` subtree

Status: ACTIVE

## Outcome

Remove the obsolete top-level `bpt2/` bootstrap/migration snapshot after proving that the current repository authority and executable paths live at the repository root (`main/`, `modules/`, `public-web/`, root `scripts/` and root `.github/workflows`).

## Evidence before change

- root `README.md` points agents to root `docs/`, `ARCHITECTURE.md` and current-work;
- `docs/LOCAL-DEVELOPMENT.md` uses only root `main/`, `modules/`, `public-web/` and root `scripts/` for supported development/bootstrap;
- `bpt2/BOOTSTRAP_STATUS.md` explicitly describes the subtree as artifacts transferred from isolated work formerly held in `igobritoti/bomprati`, and states that current repository status belongs in root `docs/MDV.md`;
- no repository search result was found that consumes the `bpt2/` path from current runtime/docs/workflows;
- workflows below `bpt2/.github/workflows` are not root GitHub Actions workflows and are not part of the active workflow inventory.

## Scope

- delete only the top-level `bpt2/` subtree;
- do not change current runtime behavior, modules, product contracts or active root workflows;
- refresh generated repository facts after deletion;
- record the authority cleanup in current-work/plan closeout.

## Acceptance

1. `bpt2/` is absent from the candidate tree;
2. root canonical paths remain unchanged except documentation/generated facts needed for this cleanup;
3. generated repository facts match the candidate tree;
4. Harness Gate passes on the exact PR head;
5. any additional workflow triggered by the deletion is green or proven unrelated infrastructure;
6. review/base refresh is clean before merge.

## Rollback

The deleted subtree remains recoverable from Git history; rollback is a normal revert/restore from the pre-removal commit.
