namespace BomPraTi.Marketplace.Contracts;

public sealed record FavoritePriceDropMatchDto(
    Guid Id,
    Guid ListingId,
    Guid ListingPriceChangeId,
    decimal PreviousPrice,
    decimal NewPrice,
    DateTime DetectedAtUtc);
