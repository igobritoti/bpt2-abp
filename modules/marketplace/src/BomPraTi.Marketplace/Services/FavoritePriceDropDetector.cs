using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Guids;

namespace BomPraTi.Marketplace.Services;

public sealed class FavoritePriceDropDetector : ITransientDependency
{
    private readonly IRepository<Favorite, Guid> _favorites;
    private readonly IRepository<FavoritePriceDropMatch, Guid> _matches;
    private readonly IGuidGenerator _guidGenerator;

    public FavoritePriceDropDetector(
        IRepository<Favorite, Guid> favorites,
        IRepository<FavoritePriceDropMatch, Guid> matches,
        IGuidGenerator guidGenerator)
    {
        _favorites = favorites;
        _matches = matches;
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

        var favoritesQuery = await _favorites.GetQueryableAsync();
        var favoriteUserIds = await favoritesQuery
            .AsNoTracking()
            .Where(x =>
                x.ListingId == priceChange.ListingId
                && x.CreatedAtUtc.HasValue
                && x.CreatedAtUtc.Value <= priceChange.ChangedAtUtc)
            .Select(x => x.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        if (favoriteUserIds.Count == 0)
        {
            return;
        }

        var matchesQuery = await _matches.GetQueryableAsync();
        var existingUserIds = await matchesQuery
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
            await _matches.InsertAsync(
                new FavoritePriceDropMatch(
                    _guidGenerator.Create(),
                    userId,
                    priceChange.ListingId,
                    priceChange.Id,
                    priceChange.PreviousPrice,
                    priceChange.NewPrice,
                    detectedAtUtc),
                autoSave: false,
                cancellationToken: cancellationToken);
        }
    }
}
