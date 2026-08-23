# ADR-0008 — Gate 01: module DbContexts and shared ABP Unit of Work

Status: Accepted

Date: 2026-08-22

## Context

The initial BPT2 blueprint considered replacing module DbContexts with a merged host DbContext. That added coupling and configuration before there was evidence that BPT2 needed it.

Gate 01 exercised the current compact modular-monolith composition using separate Catalog, Media, Sellers, Marketplace and Ingestion DbContexts against one PostgreSQL database.

## Evidence

Class B — reproduced in BPT2 GitHub Actions:

- ABP 10.6 host with the five modules built successfully;
- a fresh PostgreSQL database accepted host and module migrations;
- Draft listings were excluded from the public query;
- a different authenticated seller could not mutate another seller's listing;
- a stale Listing update raised an ABP concurrency conflict instead of silently overwriting data;
- writes through CatalogDbContext and MarketplaceDbContext inside one ABP Unit of Work were both rolled back after an intentional failure.

## Decision

For the current modular-monolith baseline:

- keep one implementation DbContext per module;
- keep cross-module dependencies through Contracts/events, never another module's DbContext;
- use ABP Unit of Work for transactional business operations on the same PostgreSQL database;
- do not introduce a merged host DbContext or ReplaceDbContext solely for transaction sharing.

## Scope limit

The rollback result applies only to participating DbContexts using the same PostgreSQL database and ABP Unit of Work. It does not establish atomicity across external APIs, object storage, message brokers, another physical database or another process. Those cases require explicit retry/idempotency/outbox/workflow/compensation decisions when they are introduced.

## Reversibility

High. A merged host DbContext can still be introduced later if a measured requirement justifies it. Gate 01 shows it is not required for the current slice.
