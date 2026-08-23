namespace BomPraTi.Marketplace.Contracts;

public sealed record SellerListingDetailDto(
    ListingDto Listing,
    IReadOnlyList<ListingPhotoDto> Photos);
