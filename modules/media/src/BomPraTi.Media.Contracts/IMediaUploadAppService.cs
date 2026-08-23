using Volo.Abp.Application.Services;
using Volo.Abp.Content;

namespace BomPraTi.Media.Contracts;

public interface IMediaUploadAppService : IApplicationService
{
    Task<MediaAssetRefDto> UploadAsync(
        IRemoteStreamContent content,
        CancellationToken cancellationToken = default);
}
