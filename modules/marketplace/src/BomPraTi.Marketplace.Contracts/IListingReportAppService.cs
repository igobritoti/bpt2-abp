using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IListingReportAppService : IApplicationService
{
    Task ReportAsync(Guid listingId, CancellationToken cancellationToken = default);

    Task<bool> GetIsReportedAsync(Guid listingId, CancellationToken cancellationToken = default);
}
