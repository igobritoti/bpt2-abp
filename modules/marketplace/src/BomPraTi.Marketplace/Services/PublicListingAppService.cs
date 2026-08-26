using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Content;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;

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

    public async Task<PublicListingDto?> GetAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var listing = await _query.GetAsync(id, cancellationToken);
        if (listing is null)
        {
            return null;
        }

        var sponsored = await LoadActiveSponsoredListingIdsAsync(new[] { id }, cancellationToken);
        return listing with { IsSponsored = sponsored.Contains(id) };
    }

    public async Task<PagedResultDto<PublicListingDto>> GetListAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default)
    {
        var page = await _query.SearchPageAsync(input, cancellationToken);
        if (page.Items.Count == 0)
        {
            return page;
        }

        var sponsored = await LoadActiveSponsoredListingIdsAsync(
            page.Items.Select(x => x.Id).ToArray(),
            cancellationToken);
        var items = page.Items
            .Select(x => x with { IsSponsored = sponsored.Contains(x.Id) })
            .ToList();
        return new PagedResultDto<PublicListingDto>(page.TotalCount, items);
    }

    public async Task<IRemoteStreamContent> GetPhotoAsync(
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
            throw new EntityNotFoundException<ListingPhoto>(photoId);
        }

        var media = await _mediaContent.OpenReadAsync(mediaAssetId.Value, cancellationToken);
        if (media is null)
        {
            throw new EntityNotFoundException<ListingPhoto>(photoId);
        }

        return new RemoteStreamContent(media.Content, null, media.ContentType, media.Length);
    }

    private async Task<HashSet<Guid>> LoadActiveSponsoredListingIdsAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken)
    {
        if (listingIds.Count == 0)
        {
            return new HashSet<Guid>();
        }

        var now = DateTime.UtcNow;
        var ids = await _dbContext.ListingPromotions
            .AsNoTracking()
            .Where(x => listingIds.Contains(x.ListingId))
            .Where(x => x.StartsAtUtc <= now && now < x.EndsAtUtc)
            .Select(x => x.ListingId)
            .ToListAsync(cancellationToken);
        return ids.ToHashSet();
    }
}
