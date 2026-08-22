# BPT2 repository migration gate

Source repository: `igobritoti/bomprati`

Source branch: `bpt2-vertical-slice-20260822`

Destination repository: `igobritoti/bpt2abp`

Destination migration branch: `migrate-bpt2-assets-20260822`

## Safety rule

Nothing under the BPT2 subtree is removed from the source until the destination copy is complete and its minimum executable gates pass.

## Completion criteria

1. Code, migrations, scripts, smoke tests, workflows and ADRs are present in the destination.
2. The migrated tree is inspected for missing files and secrets.
3. ABP/.NET build passes in destination CI.
4. Fresh PostgreSQL migration passes.
5. Architecture-boundary gate passes.
6. Public Draft visibility, seller ownership and optimistic-concurrency critical smokes pass when applicable to the migrated slice.
7. Only after 1–6 pass may the BPT2 subtree/workflow be removed from the source branch/repository.

## Epistemic rule

Historical PASS results from the source are evidence, but repository-level status in the destination remains `NAO_DECIDIDO` until the corresponding destination gate executes successfully.
