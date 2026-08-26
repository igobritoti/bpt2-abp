namespace BomPraTi.Marketplace.Contracts;

public sealed record SavedSearchAlertMatchDto(
    Guid Id,
    Guid SavedSearchId,
    Guid ListingId,
    DateTime DetectedAtUtc);
