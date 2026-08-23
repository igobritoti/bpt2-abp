namespace BomPraTi.Marketplace.Contracts;

public sealed record SellerLeadDto(
    Guid Id,
    Guid ListingId,
    string ListingTitle,
    Guid? BuyerUserId,
    string Channel,
    DateTime CreatedAtUtc);
