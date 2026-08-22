namespace BomPraTi.Sellers.Contracts;

public sealed record SellerPublicContactDto(
    Guid SellerId,
    string DisplayName,
    string WhatsAppNumber);
