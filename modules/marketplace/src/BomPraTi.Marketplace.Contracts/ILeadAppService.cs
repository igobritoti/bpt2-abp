using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ILeadAppService : IApplicationService
{
    Task CreateAsync(Guid listingId, CancellationToken cancellationToken = default);
}
