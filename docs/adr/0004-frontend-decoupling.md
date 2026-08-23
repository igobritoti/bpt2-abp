# ADR-0004: Public frontend is decoupled from the ABP host

Status: Accepted

## Decision

The ABP application uses a no-UI backend baseline. Public marketplace UX/SEO is an independent client of the application API.

ABP administrative capabilities may be introduced separately if useful, but public-web framework choice must not leak into Catalog, Marketplace, Sellers, Media or Ingestion assemblies.
