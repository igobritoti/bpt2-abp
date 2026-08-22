# ADR-0005: Compact business-module convention

Status: Accepted provisionally; revisit against current ABP 10.6 module documentation before expanding the module graph.

## Decision

The current BPT2 code uses two assemblies per business capability:

- `BomPraTi.<Capability>.Contracts`: cross-module interfaces and DTOs;
- `BomPraTi.<Capability>`: domain, application and persistence implementation.

The executable host is the composition root and references implementations. Business implementations reference only other modules' Contracts assemblies.

## Revisit trigger

Revisit if the current official ABP Standard Module path provides the same compact boundaries with less custom convention, or if executable maintenance evidence shows the current shape is insufficient.
