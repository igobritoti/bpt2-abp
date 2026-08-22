using BomPraTi.Media.Contracts;
using BomPraTi.Media.Data;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Media.Services;

public sealed class MediaAssetReader : IMediaAssetReader, ITransientDependency
{
    private readonly MediaDbContext _dbContext;

    public MediaAssetReader(MediaDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<MediaAssetRefDto?> GetAsync(Guid mediaAssetId, CancellationToken cancellationToken = default)
    {
        return _dbContext.MediaAssets
            .AsNoTracking()
            .Where(x => x.Id == mediaAssetId)
            .Select(x => new MediaAssetRefDto(x.Id, x.ContentType, x.Length))
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MediaAssetRefDto>> GetManyAsync(
        IReadOnlyCollection<Guid> mediaAssetIds,
        CancellationToken cancellationToken = default)
    {
        if (mediaAssetIds.Count == 0)
        {
            return Array.Empty<MediaAssetRefDto>();
        }

        return await _dbContext.MediaAssets
            .AsNoTracking()
            .Where(x => mediaAssetIds.Contains(x.Id))
            .Select(x => new MediaAssetRefDto(x.Id, x.ContentType, x.Length))
            .ToListAsync(cancellationToken);
    }
}
