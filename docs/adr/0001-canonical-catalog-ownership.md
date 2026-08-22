# ADR-0001: Catalog is the canonical automotive authority

Status: Accepted

## Decision

`BomPraTi.Catalog` is the sole owner allowed to mutate canonical Brand, Model, Generation, Version and Vehicle identity.

External data sources, including Buscador, are ingestion/enrichment inputs. They do not become sources of truth by being imported.

## Consequences

- Marketplace stores `VehicleId`, not a duplicated vehicle graph.
- Ingestion stores provenance/confidence/reconciliation state and calls Catalog through contracts.
- Catalog writes are validated and auditable.
- Cross-module EF navigation properties into Catalog are prohibited.
