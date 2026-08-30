using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchEmailProviderEventProcessor : ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;

    public SavedSearchEmailProviderEventProcessor(MarketplaceDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task ProcessAsync(
        string provider,
        string providerEventId,
        string providerMessageId,
        string eventType,
        CancellationToken cancellationToken = default)
    {
        var normalizedProvider = provider.Trim().ToLowerInvariant();
        var normalizedEventId = providerEventId.Trim();
        if (await _dbContext.SavedSearchEmailProviderEvents.AsNoTracking()
            .AnyAsync(x => x.Provider == normalizedProvider && x.ProviderEventId == normalizedEventId, cancellationToken))
        {
            return;
        }

        await using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            if (await _dbContext.SavedSearchEmailProviderEvents.AsNoTracking()
                .AnyAsync(x => x.Provider == normalizedProvider && x.ProviderEventId == normalizedEventId, cancellationToken))
            {
                await transaction.RollbackAsync(cancellationToken);
                return;
            }

            var intent = await _dbContext.SavedSearchAlertDeliveryIntents
                .SingleOrDefaultAsync(x => x.ProviderMessageId == providerMessageId, cancellationToken);

            if (intent is not null)
            {
                switch (eventType.Trim().ToLowerInvariant())
                {
                    case "email.delivered":
                        intent.MarkDelivered();
                        break;
                    case "email.bounced":
                    case "email.complained":
                    case "email.failed":
                        if (intent.Status != SavedSearchAlertDeliveryStatus.Delivered)
                        {
                            intent.MarkPermanentFailed();
                        }
                        break;
                }
            }

            await _dbContext.SavedSearchEmailProviderEvents.AddAsync(
                new SavedSearchEmailProviderEvent(
                    Guid.NewGuid(),
                    normalizedProvider,
                    normalizedEventId,
                    providerMessageId,
                    eventType,
                    DateTime.UtcNow),
                cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync(CancellationToken.None);
            _dbContext.ChangeTracker.Clear();
            if (await _dbContext.SavedSearchEmailProviderEvents.AsNoTracking()
                .AnyAsync(x => x.Provider == normalizedProvider && x.ProviderEventId == normalizedEventId, CancellationToken.None))
            {
                return;
            }
            throw;
        }
    }
}
