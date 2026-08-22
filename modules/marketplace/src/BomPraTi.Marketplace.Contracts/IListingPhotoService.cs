namespace BomPraTi.Marketplace.Contracts;

public interface IListingPhotoService
{
    Task<IReadOnlyList<ListingPhotoDto>> AttachAsync(
        Guid listingId,
        AttachListingPhotoInput input,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ListingPhotoDto>> ReorderAsync(
        Guid listingId,
        ReorderListingPhotosInput input,
        CancellationToken cancellationToken = default);

    Task RemoveAsync(Guid listingId, Guid photoId, CancellationToken cancellationToken = default);
}
