namespace BomPraTi.Catalog.Contracts;

public sealed record VehicleRefDto(
    Guid Id,
    string Brand,
    string Model,
    string? Generation,
    string Version,
    int? ModelYear,
    string? Powertrain,
    string? Transmission,
    string? BodyStyle);
