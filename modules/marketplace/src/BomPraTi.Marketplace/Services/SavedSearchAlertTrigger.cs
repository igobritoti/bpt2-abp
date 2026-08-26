using BomPraTi.Marketplace.Domain;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;

namespace BomPraTi.Marketplace.Services;

public class SavedSearchAlertTrigger : ITransientDependency
{
    private readonly IRepository<SavedSearchAlertDetectionRequest, Guid> _requests;

    public SavedSearchAlertTrigger(IRepository<SavedSearchAlertDetectionRequest, Guid> requests)
    {
        _requests = requests;
    }

    public async Task EnsureEnqueuedAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (await _requests.AnyAsync(x => x.ListingId == listingId, cancellationToken: cancellationToken))
        {
            return;
        }

        await _requests.InsertAsync(
            new SavedSearchAlertDetectionRequest(Guid.NewGuid(), listingId, DateTime.UtcNow),
            autoSave: true,
            cancellationToken: cancellationToken);
    }
}
