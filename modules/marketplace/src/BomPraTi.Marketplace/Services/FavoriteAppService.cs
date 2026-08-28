using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class FavoriteAppService : IFavoriteAppService, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;
    private readonly IPublicListingQuery _publicListings;

    public FavoriteAppService(
        MarketplaceDbContext dbContext,
        ICurrentUser currentUser,
        IPublicListingQuery publicListings)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _publicListings = publicListings;
    }

    public async Task AddAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            throw new EntityNotFoundException<Listing>(listingId);
        }

        var exists = await _dbContext.Favorites
            .AsNoTracking()
            .AnyAsync(x => x.UserId == userId && x.ListingId == listingId, cancellationToken);
        if (exists)
        {
            return;
        }

        await _dbContext.Favorites.AddAsync(
            new Favorite(Guid.NewGuid(), userId, listingId, DateTime.UtcNow),
            cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        var favorite = await _dbContext.Favorites
            .SingleOrDefaultAsync(x => x.UserId == userId && x.ListingId == listingId, cancellationToken);
        if (favorite is null)
        {
            return;
        }

        _dbContext.Favorites.Remove(favorite);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> GetIsFavoriteAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            return false;
        }

        return await _dbContext.Favorites
            .AsNoTracking()
            .AnyAsync(x => x.UserId == userId && x.ListingId == listingId, cancellationToken);
    }

    public async Task<IReadOnlyList<PublicListingDto>> GetMineAsync(CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        var listingIds = await _dbContext.Favorites
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.Id)
            .Select(x => x.ListingId)
            .ToListAsync(cancellationToken);

        return await _publicListings.GetManyAsync(listingIds, cancellationToken);
    }

    public async Task<IReadOnlyList<FavoritePriceDropMatchDto>> GetPriceDropMatchesAsync(
        CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        return await _dbContext.FavoritePriceDropMatches
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.DetectedAtUtc)
            .ThenBy(x => x.Id)
            .Select(x => new FavoritePriceDropMatchDto(
                x.Id,
                x.ListingId,
                x.ListingPriceChangeId,
                x.PreviousPrice,
                x.NewPrice,
                x.DetectedAtUtc))
            .ToListAsync(cancellationToken);
    }

    private Guid CurrentUserId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated Buyer is required.");
}
