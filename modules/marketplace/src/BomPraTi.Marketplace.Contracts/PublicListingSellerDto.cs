namespace BomPraTi.Marketplace.Contracts;

public sealed record PublicListingSellerDto(
    Guid SellerId,
    string? DisplayName);
