using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

public class SavedSearchAlertTrigger : ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;

    public SavedSearchAlertTrigger(MarketplaceDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task EnsureEnqueuedAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (await _dbContext.SavedSearchAlertDetectionRequests
            .AsNoTracking()
            .AnyAsync(x => x.ListingId == listingId, cancellationToken))
        {
            return;
        }

        await _dbContext.SavedSearchAlertDetectionRequests.AddAsync(
            new SavedSearchAlertDetectionRequest(Guid.NewGuid(), listingId, DateTime.UtcNow),
            cancellationToken);
    }
}
