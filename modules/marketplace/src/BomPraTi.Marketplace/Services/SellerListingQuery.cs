using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class SellerListingQuery : ISellerListingQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;

    public SellerListingQuery(MarketplaceDbContext dbContext, ICurrentUser currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
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

    private Guid CurrentSellerId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");
}
