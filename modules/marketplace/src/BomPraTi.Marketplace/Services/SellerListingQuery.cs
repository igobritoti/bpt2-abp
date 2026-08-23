using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Content;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class SellerListingQuery : ISellerListingQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;
    private readonly IMediaContentReader _mediaContent;

    public SellerListingQuery(
        MarketplaceDbContext dbContext,
        ICurrentUser currentUser,
        IMediaContentReader mediaContent)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _mediaContent = mediaContent;
    }

    public async Task<IReadOnlyList<ListingDto>> GetMineAsync(CancellationToken cancellationToken = default)
    {
        var sellerId = CurrentSellerId();

        return await _dbContext.Listings
            .AsNoTracking()
            .Where(x => x.SellerId == sellerId)
            .OrderBy(x => x.Id)
            .Select(x => new ListingDto(
                x.Id,
                x.SellerId,
                x.VehicleId,
                x.Title,
                x.Price,
                x.Description,
                x.ManufactureYear,
                x.MileageKm,
                x.Color,
                x.City,
                x.StateCode,
                x.Status.ToString(),
                x.ConcurrencyStamp))
            .ToListAsync(cancellationToken);
    }

    public async Task<SellerListingDetailDto?> GetMineByIdAsync(
        Guid listingId,
        CancellationToken cancellationToken = default)
    {
        var sellerId = CurrentSellerId();

        var listing = await _dbContext.Listings
            .AsNoTracking()
            .Where(x => x.Id == listingId && x.SellerId == sellerId)
            .Select(x => new ListingDto(
                x.Id,
                x.SellerId,
                x.VehicleId,
                x.Title,
                x.Price,
                x.Description,
                x.ManufactureYear,
                x.MileageKm,
                x.Color,
                x.City,
                x.StateCode,
                x.Status.ToString(),
                x.ConcurrencyStamp))
            .SingleOrDefaultAsync(cancellationToken);

        if (listing is null)
        {
            return null;
        }

        var photos = await _dbContext.ListingPhotos
            .AsNoTracking()
            .Where(x => x.ListingId == listingId)
            .OrderBy(x => x.SortOrder)
            .ThenBy(x => x.Id)
            .Select(x => new ListingPhotoDto(x.Id, x.MediaAssetId, x.SortOrder))
            .ToListAsync(cancellationToken);

        return new SellerListingDetailDto(listing, photos);
    }

    public async Task<IRemoteStreamContent> GetMinePhotoAsync(
        Guid listingId,
        Guid photoId,
        CancellationToken cancellationToken = default)
    {
        var sellerId = CurrentSellerId();

        var mediaAssetId = await _dbContext.Listings
            .AsNoTracking()
            .Where(listing => listing.Id == listingId && listing.SellerId == sellerId)
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

    private Guid CurrentSellerId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");
}
