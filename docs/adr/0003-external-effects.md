# ADR-0003: External side effects require durable coordination

Status: Accepted

## Decision

Any operation involving payments, credits, promotion entitlement, reports, assisted purchase, critical messaging or another external provider must be designed with idempotency, durable operation state, transactional outbox where a DB commit must cause later work, retry policy, and explicit compensation/reconciliation when needed.

A domain transaction must not depend on `await provider.Call()` followed by an unrelated persistence step as its consistency model.
