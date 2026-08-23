# BPT2 — agent map

The repository is the system of record. Start small; follow links only for the task at hand.

## Start here

1. `docs/agent/CURRENT-WORK.md` — current factual state, active plan and next acceptance target.
2. `docs/README.md` — knowledge map and canonical source by subject.
3. Read only the specialized sources required by the task boundary.

## Canonical sources

- Product and scope: `docs/PRODUCT.md`
- Architecture and module ownership: `ARCHITECTURE.md`
- Decisions and evidence state: `docs/MDV.md` and `docs/adr/`
- Engineering/autonomy/Git workflow: `docs/ENGINEERING.md`
- Validation, evidence and Definition of Done: `docs/QUALITY.md`
- Security boundaries: `docs/SECURITY.md`
- Execution-plan policy: `docs/PLANS.md`
- Active/completed plans and technical debt: `docs/exec-plans/`
- Derived repository facts: `docs/generated/repository-facts.md`

## Execution

For implementation work, follow the autonomous loop in `docs/ENGINEERING.md`: edit → validate → self-review → commit/push/PR → inspect CI → fix/repeat → merge when authorized and allowed. Stop only at the acceptance criterion or a real external blocker.

Run `python3 scripts/check-harness.py` after changing harness/docs and the risk-specific checks selected by `docs/QUALITY.md`.

Do not copy recurring policy into prompts or new Markdown. Put each recurring rule in its canonical source and link to it.
