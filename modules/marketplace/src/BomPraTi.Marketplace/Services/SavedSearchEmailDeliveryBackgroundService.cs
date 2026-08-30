using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchEmailDeliveryBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SavedSearchEmailDeliveryBackgroundService> _logger;
    private readonly SavedSearchEmailDeliveryOptions _options;

    public SavedSearchEmailDeliveryBackgroundService(
        IServiceScopeFactory scopeFactory,
        IOptions<SavedSearchEmailDeliveryOptions> options,
        ILogger<SavedSearchEmailDeliveryBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _options = options.Value;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_options.Enabled)
        {
            _logger.LogInformation("Saved search email delivery runner disabled by configuration.");
            return;
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var processor = scope.ServiceProvider.GetRequiredService<SavedSearchEmailDeliveryProcessor>();
                var processed = await processor.ProcessNextAsync(stoppingToken);
                if (!processed)
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
                _logger.LogError(exception, "Saved search email delivery iteration failed.");
                await Task.Delay(_options.IdleDelay, stoppingToken);
            }
        }
    }
}
