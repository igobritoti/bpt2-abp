namespace BomPraTi.Marketplace.Contracts;

public sealed record ListingPhotoDto(
    Guid Id,
    Guid MediaAssetId,
    int SortOrder);
