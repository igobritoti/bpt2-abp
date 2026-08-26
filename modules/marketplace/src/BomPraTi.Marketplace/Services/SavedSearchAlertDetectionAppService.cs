using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

[Authorize(Roles = "admin")]
public class SavedSearchAlertDetectionAppService : ISavedSearchAlertDetectionAppService, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly IPublicListingQuery _publicListings;

    public SavedSearchAlertDetectionAppService(
        MarketplaceDbContext dbContext,
        IPublicListingQuery publicListings)
    {
        _dbContext = dbContext;
        _publicListings = publicListings;
    }

    public async Task<int> EvaluateAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            return 0;
        }

        var savedSearches = await _dbContext.SavedSearches
            .AsNoTracking()
            .Where(x => x.AlertEnabled)
            .OrderBy(x => x.Id)
            .ToListAsync(cancellationToken);
        if (savedSearches.Count == 0)
        {
            return 0;
        }

        var existing = await _dbContext.SavedSearchAlertMatches
            .AsNoTracking()
            .Where(x => x.ListingId == listingId)
            .Select(x => x.SavedSearchId)
            .ToListAsync(cancellationToken);
        var existingIds = existing.ToHashSet();
        var detectedAtUtc = DateTime.UtcNow;
        var added = 0;

        foreach (var savedSearch in savedSearches)
        {
            if (existingIds.Contains(savedSearch.Id))
            {
                continue;
            }

            if (!await _publicListings.MatchesAsync(listingId, ToPublicSearch(savedSearch), cancellationToken))
            {
                continue;
            }

            await _dbContext.SavedSearchAlertMatches.AddAsync(
                new SavedSearchAlertMatch(Guid.NewGuid(), savedSearch.Id, listingId, detectedAtUtc),
                cancellationToken);
            existingIds.Add(savedSearch.Id);
            added++;
        }

        if (added > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return added;
    }

    private static PublicListingSearchInput ToPublicSearch(SavedSearch savedSearch) => new()
    {
        VehicleId = savedSearch.VehicleId,
        SellerId = savedSearch.SellerId,
        Brand = savedSearch.Brand,
        Model = savedSearch.Model,
        City = savedSearch.City,
        StateCode = savedSearch.StateCode,
        MinModelYear = savedSearch.MinModelYear,
        MaxModelYear = savedSearch.MaxModelYear,
        MinPrice = savedSearch.MinPrice,
        MaxPrice = savedSearch.MaxPrice,
        MinMileageKm = savedSearch.MinMileageKm,
        MaxMileageKm = savedSearch.MaxMileageKm,
        Query = savedSearch.Query
    };
}
