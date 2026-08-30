using System.Data;
using BomPraTi.Marketplace.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchAlertRunnerBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SavedSearchAlertRunnerBackgroundService> _logger;
    private readonly SavedSearchAlertRunnerOptions _options;

    public SavedSearchAlertRunnerBackgroundService(
        IServiceScopeFactory scopeFactory,
        IOptions<SavedSearchAlertRunnerOptions> options,
        ILogger<SavedSearchAlertRunnerBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _options = options.Value;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_options.Enabled)
        {
            _logger.LogInformation("Saved search alert runner disabled by configuration.");
            return;
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var processedAny = await ProcessUntilIdleAsync(stoppingToken);
                if (!processedAny)
                {
                    await Task.Delay(_options.IdleDelay, stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Saved search alert runner iteration failed.");
                await Task.Delay(_options.IdleDelay, stoppingToken);
            }
        }
    }

    private async Task<bool> ProcessUntilIdleAsync(CancellationToken cancellationToken)
    {
        var processedAny = false;
        while (!cancellationToken.IsCancellationRequested)
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
            var processor = scope.ServiceProvider.GetRequiredService<SavedSearchAlertDetectionProcessor>();
            var nowUtc = DateTime.UtcNow;

            await using var transaction = await dbContext.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, cancellationToken);
            var request = await dbContext.SavedSearchAlertDetectionRequests
                .FromSqlInterpolated($"""
                    SELECT *
                    FROM "MarketplaceSavedSearchAlertDetectionRequests"
                    WHERE "ProcessedAtUtc" IS NULL
                      AND ("NextAttemptAtUtc" IS NULL OR "NextAttemptAtUtc" <= {nowUtc})
                    ORDER BY "EnqueuedAtUtc", "Id"
                    LIMIT 1
                    FOR UPDATE SKIP LOCKED
                    """)
                .SingleOrDefaultAsync(cancellationToken);

            if (request is null)
            {
                await transaction.RollbackAsync(cancellationToken);
                return processedAny;
            }

            await processor.EvaluateAsync(request.ListingId, cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            processedAny = true;
        }

        return processedAny;
    }
}
