using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IFavoriteAppService : IApplicationService
{
    Task AddAsync(Guid listingId, CancellationToken cancellationToken = default);

    Task RemoveAsync(Guid listingId, CancellationToken cancellationToken = default);

    Task<bool> GetIsFavoriteAsync(Guid listingId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PublicListingDto>> GetMineAsync(CancellationToken cancellationToken = default);
}
