namespace BomPraTi.Marketplace.Contracts;

public sealed record CreateListingInput(
    Guid VehicleId,
    string Title,
    decimal Price,
    string Description,
    int? ManufactureYear,
    int? MileageKm,
    string? Color,
    string City,
    string StateCode);
