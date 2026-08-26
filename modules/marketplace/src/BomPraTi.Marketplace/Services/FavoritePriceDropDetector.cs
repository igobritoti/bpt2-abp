using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Guids;

namespace BomPraTi.Marketplace.Services;

public sealed class FavoritePriceDropDetector : ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly IGuidGenerator _guidGenerator;

    public FavoritePriceDropDetector(MarketplaceDbContext dbContext, IGuidGenerator guidGenerator)
    {
        _dbContext = dbContext;
        _guidGenerator = guidGenerator;
    }

    public async Task DetectAsync(
        ListingPriceChange priceChange,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(priceChange);
        if (priceChange.NewPrice >= priceChange.PreviousPrice)
        {
            return;
        }

        var favoriteUserIds = await _dbContext.Favorites
            .AsNoTracking()
            .Where(x => x.ListingId == priceChange.ListingId)
            .Select(x => x.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        if (favoriteUserIds.Count == 0)
        {
            return;
        }

        var existingUserIds = await _dbContext.FavoritePriceDropMatches
            .AsNoTracking()
            .Where(x =>
                x.ListingPriceChangeId == priceChange.Id
                && favoriteUserIds.Contains(x.UserId))
            .Select(x => x.UserId)
            .ToListAsync(cancellationToken);
        var existing = existingUserIds.ToHashSet();
        var detectedAtUtc = DateTime.UtcNow;

        foreach (var userId in favoriteUserIds.Where(x => !existing.Contains(x)))
        {
            await _dbContext.FavoritePriceDropMatches.AddAsync(
                new FavoritePriceDropMatch(
                    _guidGenerator.Create(),
                    userId,
                    priceChange.ListingId,
                    priceChange.Id,
                    priceChange.PreviousPrice,
                    priceChange.NewPrice,
                    detectedAtUtc),
                cancellationToken);
        }
    }
}
