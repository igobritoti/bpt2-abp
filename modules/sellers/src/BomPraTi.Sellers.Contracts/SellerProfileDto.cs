namespace BomPraTi.Sellers.Contracts;

public sealed record SellerProfileDto(
    Guid Id,
    string DisplayName,
    string WhatsAppNumber);
