namespace BomPraTi.Marketplace.Contracts;

public sealed record PublicListingPhotoDto(
    Guid Id,
    Guid MediaAssetId,
    string ContentType,
    long Length,
    int SortOrder);
