# Paired CI cost probe — 2026-09-03

## Question

For the current BPT2 backend/frontend partition, what paired build/check compute and modeled critical-path difference appears between a combined tree and independent backend/frontend snapshots?

## Protocol authority

Pre-registered protocol: `docs/exec-plans/completed/0066-paired-ci-cost-probe.md` (opened under `active/` before results).

Frozen source `main`: `4bdf7475d77320505bf4861fe39c3b18da54c40d`.

## Authoritative execution

Workflow: `BPT2 Paired CI Cost Probe`

Run: `33824148587`

Measured head: `74395f87f3f0009481cdf8dda8bc2b5216eb90ec`

Artifact id: `9919443682`

Artifact SHA-256: `2fec3d4d711eacb1c69abeffcdaca911153754f2c6899467ddcfebaad77e9345`

Valid pairs: **5/5**.

## Results

| Metric | Median | Ratio vs combined |
| --- | ---: | ---: |
| Combined total | 28.377 s | 1.0000 |
| Split compute | 28.650 s | 1.0096 |
| Split modeled critical path | 23.631 s | 0.8327 |

Derived differences:
- split compute: **+0.96%**;
- split modeled critical path: **-16.73%**.

## Decision-rule interpretation

The pre-registered compute penalty threshold (split >=20% above combined) did not fire.

The pre-registered critical-path benefit threshold (split >=20% below combined) did not fire.

Therefore this workload does not provide sufficient evidence to select monorepo or split based on CI compute/critical-path cost.

## Pilot disposition

Run `33823539141` completed the same 5-pair workload, but its JSON populated `head_sha` from GitHub event `GITHUB_SHA`, which is the PR merge-ref context. Job logs independently confirm checkout of PR head `2308b81fb2e7cd746baba6e9caebffbaeacc5c9b`. To keep artifact identity self-contained, the script was corrected to record `git rev-parse HEAD`; the pilot is retained only as a stability check and is not the authoritative result.

The pilot medians were close to the authoritative result (split compute -0.09%; split modeled critical path -16.52%), supporting run-to-run consistency without being pooled into the preregistered five-pair sample.

## Scope limits

This is a same-runner paired build/check experiment. The split critical path is modeled as the maximum of backend and frontend streams; two independent GitHub jobs were not timed end-to-end. The study does not measure deployment, rollback, queue/startup overhead, human coordination, PR lead time, maintenance, incident risk, or financial cost.
