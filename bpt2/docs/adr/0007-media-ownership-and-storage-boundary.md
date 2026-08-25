# ADR-0007 — Media ownership and storage boundary

Status: Accepted for the migrated baseline; architectural evidence level C, executable preservation evidence B must be rerun in this repository.

## Decision

`Media` owns `MediaAsset` identity and provider-specific storage metadata. `Marketplace` owns `ListingPhoto`, but a listing photo stores only `MediaAssetId` and ordering metadata.

Marketplace may depend on `BomPraTi.Media.Contracts`; it must never reference the Media implementation or a provider storage key.

`MediaAssetId`, not `StorageKey`, is the asset identity. The binary/object-storage provider is deliberately not selected in this ADR.

## Upgrade rule

The transition from the bootstrap `ListingPhoto.StorageKey` model is data-preserving. The deployment migration order is Media first, Marketplace second. For pre-existing listing-photo rows, the migration creates a MediaAsset before removing the Marketplace storage column. Unknown historical MIME/length metadata is represented explicitly rather than invented.

This one-time cross-module SQL handoff is a migration/composition concern, not a runtime dependency. CI must exercise previous→latest with seeded legacy rows before the transition is accepted.

## Consequences

- Changing object-storage providers does not rewrite listing aggregates or public listing contracts.
- Public listing projection exposes media identity/content metadata, not provider keys.
- There is intentionally no cross-module database FK from Marketplace to Media in the migrated baseline; this remains subject to the evidence status in the MDV rather than being generalized as a universal rule.
