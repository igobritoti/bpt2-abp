using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IPublicListingAppService : IApplicationService
{
    Task<PublicListingDto?> GetAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PublicListingDto>> GetListAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default);
}
