namespace BomPraTi.Marketplace.Contracts;

public sealed record PublicListingVehicleDto(
    Guid Id,
    string Brand,
    string Model,
    string? Generation,
    string Version,
    int? ModelYear);
