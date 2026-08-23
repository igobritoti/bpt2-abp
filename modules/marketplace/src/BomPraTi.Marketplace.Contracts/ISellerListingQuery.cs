using Volo.Abp.Application.Services;
using Volo.Abp.Content;

namespace BomPraTi.Marketplace.Contracts;

public interface ISellerListingQuery : IApplicationService
{
    Task<IReadOnlyList<ListingDto>> GetMineAsync(CancellationToken cancellationToken = default);
    Task<SellerListingDetailDto?> GetMineByIdAsync(Guid listingId, CancellationToken cancellationToken = default);
    Task<IRemoteStreamContent> GetMinePhotoAsync(
        Guid listingId,
        Guid photoId,
        CancellationToken cancellationToken = default);
}
