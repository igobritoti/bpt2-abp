namespace BomPraTi.Catalog.Contracts;

public sealed record VehicleCatalogSearchInput(
    string? Brand = null,
    string? Model = null,
    int? MinModelYear = null,
    int? MaxModelYear = null,
    string? Query = null);
