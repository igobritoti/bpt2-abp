namespace BomPraTi.Marketplace.Contracts;

public sealed record SavedSearchDto(
    Guid Id,
    Guid? VehicleId,
    Guid? SellerId,
    string? Brand,
    string? Model,
    string? Color,
    string? City,
    string? StateCode,
    int? MinModelYear,
    int? MaxModelYear,
    decimal? MinPrice,
    decimal? MaxPrice,
    int? MinMileageKm,
    int? MaxMileageKm,
    string? Query,
    bool AlertEnabled,
    DateTime? AlertEnabledAtUtc,
    DateTime CreatedAtUtc);
