# ADR-0006: Bootstrap acceptance requires executable gates

Status: Accepted

## Decision

Bootstrap is not accepted because files exist. It must pass the minimal executable gates relevant to the current slice: architecture boundaries, pinned build/toolchain, fresh database migration, critical privacy/ownership/concurrency invariants, and deterministic CI execution.

Tests beyond the risk introduced by the current slice are deferred, not deleted.
