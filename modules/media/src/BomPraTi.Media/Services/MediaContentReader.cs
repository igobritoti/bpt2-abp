using BomPraTi.Media.Contracts;
using BomPraTi.Media.Domain;
using BomPraTi.Media.Storage;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;

namespace BomPraTi.Media.Services;

public sealed class MediaContentReader : IMediaContentReader, ITransientDependency
{
    private readonly IRepository<MediaAsset, Guid> _assets;
    private readonly IMediaBlobStore _blobStore;

    public MediaContentReader(IRepository<MediaAsset, Guid> assets, IMediaBlobStore blobStore)
    {
        _assets = assets;
        _blobStore = blobStore;
    }

    public async Task<MediaContentDto?> OpenReadAsync(
        Guid mediaAssetId,
        CancellationToken cancellationToken = default)
    {
        var asset = await _assets.FindAsync(mediaAssetId, includeDetails: false, cancellationToken: cancellationToken);
        if (asset is null)
        {
            return null;
        }

        try
        {
            var content = await _blobStore.OpenReadAsync(asset.StorageKey, cancellationToken);
            return new MediaContentDto(content, asset.ContentType, asset.Length);
        }
        catch (FileNotFoundException)
        {
            return null;
        }
    }
}
