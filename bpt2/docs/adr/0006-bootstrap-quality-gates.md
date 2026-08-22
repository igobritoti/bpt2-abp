# ADR-0006: Bootstrap acceptance requires executable architecture and database gates

Status: Accepted

## Decision

BPT2 bootstrap is not accepted merely because project files exist. The baseline requires executable evidence for the risks introduced by the current slice: dependency boundaries, build, fresh database/migrations, privacy/ownership and concurrency where applicable.

Tests are added by risk, not by test-count target. Historical bootstrap checks from the isolated branch are evidence inputs, but the repository is marked PASS only after the corresponding gate runs here.
