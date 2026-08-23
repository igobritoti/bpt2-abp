using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;
using Volo.Abp.Content;

namespace BomPraTi.Marketplace.Contracts;

public interface IPublicListingAppService : IApplicationService
{
    Task<PublicListingDto?> GetAsync(Guid id, CancellationToken cancellationToken = default);

    Task<PagedResultDto<PublicListingDto>> GetListAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default);

    Task<IRemoteStreamContent> GetPhotoAsync(
        Guid id,
        Guid photoId,
        CancellationToken cancellationToken = default);
}
