using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ISellerLeadCommandService : IApplicationService
{
    Task MarkContactedAsync(Guid leadId, CancellationToken cancellationToken = default);
}
