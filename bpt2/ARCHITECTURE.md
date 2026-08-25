# BPT2 Architecture

## Deployable shape

```text
Public Web / future clients
          |
          v
+---------------------------+
| BomPraTi ABP API Host     |
| app-nolayers              |
+---------------------------+
   |          |          |
   v          v          v
Catalog   Marketplace   Ingestion
   ^          |          |
   |          |          |
   +--- Contracts <------+

PostgreSQL (single physical database initially)
```

Each business module owns its model and persistence. Cross-module database relationships are represented by identifiers, never by EF navigation properties spanning modules.

## Ownership

### Catalog
Owns canonical automotive structure:

`Brand -> Model -> Generation -> Version -> Vehicle`

Only Catalog may mutate canonical automotive identity. Other modules store canonical IDs and use Catalog contracts for reads/validation.

### Marketplace
Owns Listing, ListingPhoto, Favorite, Lead, seller/listing policies and listing lifecycle.

A public listing query must include `Published` as an invariant, not as a UI preference.

### Ingestion
Owns connectivity inputs, provenance, confidence, reconciliation proposals and import state. Ingestion proposes/feeds changes; Catalog remains canonical authority.

## Infrastructure rules

1. Authentication/Identity starts with ABP's official modules.
2. External side effects require durable coordination appropriate to the risk; see ADR-0003.
3. Distributed workers require a real distributed-lock provider when deployed with multiple workers.
4. Cross-module dependencies follow the explicit compile-time matrix and use Contracts/events, never another module's implementation assembly.
5. Contracts assemblies contain no EF/Npgsql persistence dependencies.
6. The host is the composition root.
7. Frontend code does not enter business module assemblies.
8. A fresh environment must reproduce migrations before the bootstrap is accepted.

Items whose BPT-specific choice is not established by documentation or executable evidence remain open in `docs/MDV.md`.
