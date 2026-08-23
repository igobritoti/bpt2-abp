using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ISellerListingQuery : IApplicationService
{
    Task<IReadOnlyList<ListingDto>> GetMineAsync(CancellationToken cancellationToken = default);
}
