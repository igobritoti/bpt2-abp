# ADR-0004: Public frontend is decoupled from the ABP host

Status: Accepted

## Decision

The backend baseline does not bind the public marketplace to an ABP UI framework. Public marketplace UX/SEO is an independent client of the application API.

ABP administrative capabilities may be introduced separately if useful, but public-web framework choice must not leak into Catalog, Marketplace or Ingestion assemblies.
