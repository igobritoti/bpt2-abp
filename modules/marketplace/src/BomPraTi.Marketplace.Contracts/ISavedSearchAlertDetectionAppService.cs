using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ISavedSearchAlertDetectionAppService : IApplicationService
{
    Task<int> EvaluateAsync(Guid listingId, CancellationToken cancellationToken = default);
}
