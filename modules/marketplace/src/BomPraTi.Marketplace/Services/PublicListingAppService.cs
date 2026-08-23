using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Content;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

[AllowAnonymous]
public class PublicListingAppService : IPublicListingAppService, ITransientDependency
{
    private readonly IPublicListingQuery _query;
    private readonly MarketplaceDbContext _dbContext;
    private readonly IMediaContentReader _mediaContent;

    public PublicListingAppService(
        IPublicListingQuery query,
        MarketplaceDbContext dbContext,
        IMediaContentReader mediaContent)
    {
        _query = query;
        _dbContext = dbContext;
        _mediaContent = mediaContent;
    }

    public Task<PublicListingDto?> GetAsync(Guid id, CancellationToken cancellationToken = default) =>
        _query.GetAsync(id, cancellationToken);

    public Task<IReadOnlyList<PublicListingDto>> GetListAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) =>
        _query.SearchAsync(input, cancellationToken);

    public async Task<IRemoteStreamContent?> GetPhotoAsync(
        Guid id,
        Guid photoId,
        CancellationToken cancellationToken = default)
    {
        var mediaAssetId = await ListingVisibility.PublicOnly(_dbContext.Listings.AsNoTracking())
            .Where(listing => listing.Id == id)
            .Join(
                _dbContext.ListingPhotos.AsNoTracking().Where(photo => photo.Id == photoId),
                listing => listing.Id,
                photo => photo.ListingId,
                (_, photo) => (Guid?)photo.MediaAssetId)
            .SingleOrDefaultAsync(cancellationToken);

        if (!mediaAssetId.HasValue)
        {
            return null;
        }

        var media = await _mediaContent.OpenReadAsync(mediaAssetId.Value, cancellationToken);
        if (media is null)
        {
            return null;
        }

        return new RemoteStreamContent(media.Content, null, media.ContentType, media.Length);
    }
}
