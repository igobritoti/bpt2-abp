using BomPraTi.Media.Contracts;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.Content;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Media.Services;

[Authorize]
public class MediaUploadAppService : IMediaUploadAppService, ITransientDependency
{
    private readonly IMediaUploadService _uploads;

    public MediaUploadAppService(IMediaUploadService uploads)
    {
        _uploads = uploads;
    }

    public Task<MediaAssetRefDto> UploadAsync(
        IRemoteStreamContent content,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(content);
        return _uploads.UploadAsync(content.GetStream(), content.ContentType, cancellationToken);
    }
}
