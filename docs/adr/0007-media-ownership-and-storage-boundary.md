# ADR-0007 — Media ownership and storage boundary

Status: Accepted for the BPT2 baseline.

## Decision

`Media` owns `MediaAsset` identity and provider-specific storage metadata. `Marketplace` owns `ListingPhoto`, but a listing photo stores only `MediaAssetId` and ordering metadata.

Marketplace may depend on `BomPraTi.Media.Contracts`; it must never reference the Media implementation or a provider storage key.

`MediaAssetId`, not `StorageKey`, is the asset identity. The binary/object-storage provider is deliberately not selected here.

## Consequences

- Changing object-storage providers does not rewrite listing aggregates or public contracts.
- Public listing projection exposes media identity/content metadata, not provider keys.
- Provider choice remains a separate evidence-based decision.
