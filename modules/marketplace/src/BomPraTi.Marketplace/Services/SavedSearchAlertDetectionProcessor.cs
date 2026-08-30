using System.Data;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Options;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchAlertDetectionProcessor : ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly IPublicListingQuery _publicListings;
    private readonly SavedSearchAlertRunnerOptions _options;

    public SavedSearchAlertDetectionProcessor(
        MarketplaceDbContext dbContext,
        IPublicListingQuery publicListings,
        IOptions<SavedSearchAlertRunnerOptions> options)
    {
        _dbContext = dbContext;
        _publicListings = publicListings;
        _options = options.Value;
    }

    public async Task<int> EvaluateAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        await using var localTransaction = _dbContext.Database.CurrentTransaction is null
            ? await _dbContext.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, cancellationToken)
            : null;

        var request = await _dbContext.SavedSearchAlertDetectionRequests
            .FromSqlInterpolated($"""
                SELECT *
                FROM "MarketplaceSavedSearchAlertDetectionRequests"
                WHERE "ListingId" = {listingId}
                FOR UPDATE
                """)
            .SingleOrDefaultAsync(cancellationToken);
        if (request is null || request.ProcessedAtUtc.HasValue)
        {
            await CommitLocalTransactionAsync(localTransaction, cancellationToken);
            return 0;
        }

        var enqueuedAtUtc = DateTime.SpecifyKind(request.EnqueuedAtUtc, DateTimeKind.Utc);
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            request.ScheduleRetry(DateTime.UtcNow.Add(_options.MissingListingRetryDelay));
            await _dbContext.SaveChangesAsync(cancellationToken);
            await CommitLocalTransactionAsync(localTransaction, cancellationToken);
            return 0;
        }

        var savedSearches = await _dbContext.SavedSearches
            .AsNoTracking()
            .Where(x => x.AlertEnabled
                && x.AlertEnabledAtUtc.HasValue
                && x.AlertEnabledAtUtc.Value <= enqueuedAtUtc)
            .OrderBy(x => x.Id)
            .ToListAsync(cancellationToken);

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

        request.MarkProcessed(detectedAtUtc);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await CommitLocalTransactionAsync(localTransaction, cancellationToken);
        return added;
    }

    private static Task CommitLocalTransactionAsync(
        IDbContextTransaction? localTransaction,
        CancellationToken cancellationToken) =>
        localTransaction is null
            ? Task.CompletedTask
            : localTransaction.CommitAsync(cancellationToken);

    private static PublicListingSearchInput ToPublicSearch(SavedSearch savedSearch) => new()
    {
        VehicleId = savedSearch.VehicleId,
        SellerId = savedSearch.SellerId,
        Brand = savedSearch.Brand,
        Model = savedSearch.Model,
        Color = savedSearch.Color,
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
