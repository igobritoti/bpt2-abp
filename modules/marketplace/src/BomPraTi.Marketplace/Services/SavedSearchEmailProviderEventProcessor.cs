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
        var normalizedMessageId = providerMessageId.Trim();
        var normalizedEventType = eventType.Trim().ToLowerInvariant();
        var receivedAtUtc = DateTime.UtcNow;

        await using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

        var inserted = await _dbContext.Database.ExecuteSqlInterpolatedAsync($"""
            INSERT INTO "MarketplaceSavedSearchEmailProviderEvents"
                ("Id", "Provider", "ProviderEventId", "ProviderMessageId", "EventType", "ReceivedAtUtc")
            VALUES
                ({Guid.NewGuid()}, {normalizedProvider}, {normalizedEventId}, {normalizedMessageId}, {normalizedEventType}, {receivedAtUtc})
            ON CONFLICT ("Provider", "ProviderEventId") DO NOTHING
            """, cancellationToken);

        if (inserted == 0)
        {
            await transaction.RollbackAsync(cancellationToken);
            return;
        }

        switch (normalizedEventType)
        {
            case "email.delivered":
                await _dbContext.Database.ExecuteSqlInterpolatedAsync($"""
                    UPDATE "MarketplaceSavedSearchAlertDeliveryIntents"
                    SET "Status" = {SavedSearchAlertDeliveryStatus.Delivered.ToString()},
                        "NextAttemptAtUtc" = NULL,
                        "LeaseExpiresAtUtc" = NULL
                    WHERE "ProviderMessageId" = {normalizedMessageId}
                    """, cancellationToken);
                break;
            case "email.bounced":
            case "email.complained":
            case "email.failed":
                await _dbContext.Database.ExecuteSqlInterpolatedAsync($"""
                    UPDATE "MarketplaceSavedSearchAlertDeliveryIntents"
                    SET "Status" = {SavedSearchAlertDeliveryStatus.PermanentFailed.ToString()},
                        "NextAttemptAtUtc" = NULL,
                        "LeaseExpiresAtUtc" = NULL
                    WHERE "ProviderMessageId" = {normalizedMessageId}
                      AND "Status" <> {SavedSearchAlertDeliveryStatus.Delivered.ToString()}
                    """, cancellationToken);
                break;
        }

        await transaction.CommitAsync(cancellationToken);
    }
}