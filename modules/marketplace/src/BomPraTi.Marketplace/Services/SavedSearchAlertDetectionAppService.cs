using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

[Authorize(Roles = "admin")]
public class SavedSearchAlertDetectionAppService : ISavedSearchAlertDetectionAppService, ITransientDependency
{
    private readonly SavedSearchAlertDetectionProcessor _processor;

    public SavedSearchAlertDetectionAppService(SavedSearchAlertDetectionProcessor processor)
    {
        _processor = processor;
    }

    public async Task<int> EvaluateAsync(Guid listingId, CancellationToken cancellationToken = default)
        => _processor.EvaluateAsync(listingId, cancellationToken);
}
