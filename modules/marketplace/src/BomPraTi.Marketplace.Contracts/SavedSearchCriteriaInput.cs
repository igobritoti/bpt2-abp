namespace BomPraTi.Marketplace.Contracts;

public sealed record SavedSearchCriteriaInput(
    Guid? VehicleId = null,
    Guid? SellerId = null,
    string? Brand = null,
    string? Model = null,
    string? Color = null,
    string? City = null,
    string? StateCode = null,
    int? MinModelYear = null,
    int? MaxModelYear = null,
    decimal? MinPrice = null,
    decimal? MaxPrice = null,
    int? MinMileageKm = null,
    int? MaxMileageKm = null,
    string? Query = null);
