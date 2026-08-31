# POST_MVP_OPERATIONAL_CLOSURE_MATRIX

Status: canonical closure matrix for `POST_MVP_OPERATIONAL_BASELINE_V1`

This matrix is the work-selection authority for the current baseline phase. It does not replace `docs/PRODUCT.md`; it traces baseline concerns to disposition.

## Reading rules

- `BASELINE_CLOSURE` means the item still blocks closure of the current phase.
- `POST_BASELINE` means the item is valid work, but not required to close the current baseline.
- `EXTERNAL` means the item depends on provider, license, credential, deployment, or another outside authority.
- `ADMIN` means the item depends on repository/cloud/production administration.
- `PRODUCT_DECISION` means the item needs a bounded product call before work can proceed.
- `RESEARCH` means the item needs more evidence before it can be placed in baseline closure or expansion.

## Matrix

| ID | Area | Baseline requirement / capability | Current state | Evidence | Gap | Authority | Next action |
| -- | ---- | --------------------------------- | ------------- | -------- | --- | --------- | ----------- |
| BPT2-001 | Documentary authority | Single current baseline with explicit control plane | PASS | `docs/PRODUCT.md`, `docs/QUALITY.md`, `docs/LOCAL-DEVELOPMENT.md`, this baseline | None for current phase | `../PRODUCT.md`, `../QUALITY.md`, `../LOCAL-DEVELOPMENT.md`, `../baselines/POST_MVP_OPERATIONAL_BASELINE_V1.md` | Maintain only via material re-baseline |
| BPT2-002 | Core seller journey | Seller registration/login, listing lifecycle, photos, lead handling | PASS | Product authority and merged gates already recorded | None for current phase | `../PRODUCT.md` | Reopen only for new product gap |
| BPT2-003 | Core buyer journey | Discovery, detail, WhatsApp, favorites, saved searches, reports | PASS | Product authority and merged gates already recorded | None for current phase | `../PRODUCT.md` | Reopen only for new product gap |
| BPT2-004 | Catalog / vehicle identity | Canonical catalog and vehicle-hub authority | PASS | Product authority + ADR set | None for current phase | `../PRODUCT.md`, `../adr/` | Reopen only for new product gap |
| BPT2-005 | Saved-search automation | Claim/retry runner and email engineering boundary | PASS | Product authority + audit set | External activation remains separate | `../PRODUCT.md`, `../audits/` | Treat external activation as deployment dependency |
| BPT2-006 | Workflow concurrency | Superseded PR runs are isolated/cancelled correctly | PASS | `../audits/2026-08-30-workflow-concurrency-probe.md` and merged PR #172 | None | `../audits/2026-08-30-workflow-concurrency-probe.md` | Keep as repo-internal guard |
| BPT2-007 | Main integration policy | Enforce branch-protection / ruleset policy | ADMIN | Open issue #160 | Requires repository administration | Issue #160 | Resolve only with admin authority |
| BPT2-008 | Recommendations | Ground truth before similar/upgrade experiments | POST_BASELINE | Open issue #113 | Needs data/decision, not current closure | Issue #113 | Keep in post-baseline expansion |
| BPT2-009 | Market intelligence | Source authority and stable binding | POST_BASELINE | Open issue #114 | Needs licensed provider/dataset or explicit external authority | Issue #114 | Keep in post-baseline expansion |
| BPT2-010 | Trust / inspection | Vehicle history and inspection trust contracts | POST_BASELINE | Open issue #115 | Needs provider/contract/identity decisions | Issue #115 | Keep in post-baseline expansion |
| BPT2-011 | Geographic radius | True radius semantics beyond municipality identity | POST_BASELINE | Open issue #116 | Municipality identity is already separate; radius is a product expansion | Issue #116 | Keep in post-baseline expansion |
| BPT2-012 | Operational readiness | Local bootstrap, build, migrations, and documented gate flow | PARTIAL | `../LOCAL-DEVELOPMENT.md`, `../QUALITY.md`, fresh build passes, fresh-migration gate fails closed without `BPT_DB_CONNECTION`, disposable PostgreSQL probe blocked by unavailable Docker daemon in this environment | External environment still needed to complete the clean fresh-DB bootstrap on this machine | `../LOCAL-DEVELOPMENT.md` | Re-run against a Docker-enabled or live PostgreSQL environment with documented `BPT_DB_CONNECTION` |

## Resolution summary

- `BASELINE_CLOSURE`: none currently require new engineering work.
- `POST_BASELINE`: #113, #114, #115, #116.
- `ADMIN`: #160.
- `EXTERNAL`: none currently required to close the baseline, but the operational readiness probe still needs an environment with PostgreSQL availability.

## Authority

When this matrix conflicts with older audits or planning artifacts, use the current baseline and product/quality authorities first. Historical audits remain evidence, not current command.
