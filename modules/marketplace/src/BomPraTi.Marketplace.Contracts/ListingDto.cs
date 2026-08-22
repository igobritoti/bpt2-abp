namespace BomPraTi.Marketplace.Contracts;

public sealed record ListingDto(
    Guid Id,
    Guid SellerId,
    Guid VehicleId,
    string Title,
    decimal Price,
    string Description,
    int? ManufactureYear,
    int? MileageKm,
    string? Color,
    string City,
    string StateCode,
    string Status);
