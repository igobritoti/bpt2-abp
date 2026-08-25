# ADR-0003: External side effects require durable coordination

Status: Accepted

## Decision

Operations involving payments, credits, promotion entitlement, reports, assisted purchase, critical messaging or another external provider must select durability mechanisms based on the actual failure model, including persistent idempotency where required, durable operation state, transactional outbox when a database commit must cause later work, retry policy, and explicit compensation/reconciliation when the external action is not naturally idempotent.

A domain transaction must not use `await provider.Call()` followed by an unrelated persistence step as its consistency model.
