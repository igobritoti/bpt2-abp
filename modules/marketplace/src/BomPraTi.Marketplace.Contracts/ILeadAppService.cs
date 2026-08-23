using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ILeadAppService : IApplicationService
{
    Task<LeadDto> CreateAsync(Guid listingId, CancellationToken cancellationToken = default);
}
