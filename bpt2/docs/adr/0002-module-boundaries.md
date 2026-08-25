# ADR-0002: Cross-module dependencies use Contracts or events

Status: Accepted

## Decision

A business module exposes a public `Contracts` assembly and keeps its implementation private to consumers.

Allowed example:

`BomPraTi.Marketplace -> BomPraTi.Catalog.Contracts`

Forbidden example:

`BomPraTi.Marketplace -> BomPraTi.Catalog`

The executable host is the composition root and is allowed to reference implementation assemblies.

## Enforcement

- project references express the allowed graph;
- `scripts/check-boundaries.py` rejects implementation-to-implementation references and suspicious deep imports;
- CI runs the boundary check before compilation.
