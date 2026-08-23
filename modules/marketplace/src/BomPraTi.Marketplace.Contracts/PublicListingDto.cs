namespace BomPraTi.Marketplace.Contracts;

public sealed record PublicListingDto(
    Guid Id,
    Guid VehicleId,
    PublicListingVehicleDto Vehicle,
    PublicListingSellerDto Seller,
    string Title,
    decimal Price,
    string Description,
    int? ManufactureYear,
    int? MileageKm,
    string? Color,
    string City,
    string StateCode,
    IReadOnlyList<PublicListingPhotoDto> Photos);
