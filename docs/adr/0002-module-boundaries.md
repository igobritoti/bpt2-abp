# ADR-0002: Cross-module dependencies use Contracts or events

Status: Accepted

## Decision

A business module consists of a public `Contracts` assembly and a private implementation assembly.

Allowed: `BomPraTi.Marketplace -> BomPraTi.Catalog.Contracts`.
Forbidden: `BomPraTi.Marketplace -> BomPraTi.Catalog`.

The executable host is the composition root and may reference implementation assemblies.

## Enforcement

- project references express the allowed graph;
- architecture checks reject implementation-to-implementation references and suspicious deep imports;
- CI runs the boundary check before compilation.
