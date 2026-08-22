namespace BomPraTi.Marketplace.Contracts;

public sealed record UpdateListingInput(
    string Title,
    decimal Price,
    string? Description = null,
    int? ManufactureYear = null,
    int? MileageKm = null,
    string? Color = null,
    string? City = null,
    string? StateCode = null);
