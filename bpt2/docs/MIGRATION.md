# BPT2 repository migration gate

Source repository: `igobritoti/bomprati`

Source branch: `bpt2-vertical-slice-20260822`

Destination repository: `igobritoti/bpt2abp`

Destination migration branch: `migrate-bpt2-assets-20260822`

## Current decision about BPT1

BPT1 is **not discarded** at this stage. The `igobritoti/bomprati` repository remains preserved as an operational donor/reference while BPT2 is developed and validated independently.

No cleanup, deletion or retirement of BPT1 is part of the current BPT2 flow. Any future retirement or removal of BPT1 requires a separate explicit decision and its own evidence/gate.

## Safety rule

Nothing is removed from the BPT1/source repository as part of the current BPT2 work. BPT2 artifacts may be copied or reimplemented in the destination, but the source is preserved.

## Completion criteria for BPT2 materialization

1. Code, migrations, scripts, smoke tests, workflows and ADRs needed by BPT2 are present in the destination.
2. The destination tree is inspected for missing files and secrets.
3. ABP/.NET build passes in destination CI.
4. Fresh PostgreSQL migration passes.
5. Architecture-boundary gate passes.
6. Public Draft visibility, seller ownership and optimistic-concurrency critical smokes pass when applicable to the migrated slice.
7. Passing 1–6 validates the BPT2 destination only; it does **not** authorize deletion or retirement of BPT1.

## Epistemic rule

Historical PASS results from the source are evidence, but repository-level status in the destination remains `NAO_DECIDIDO` until the corresponding destination gate executes successfully.
