namespace BomPraTi.Marketplace.Contracts;

public sealed record LeadDto(
    Guid Id,
    Guid ListingId,
    Guid? UserId,
    string Channel,
    DateTime CreatedAtUtc);
