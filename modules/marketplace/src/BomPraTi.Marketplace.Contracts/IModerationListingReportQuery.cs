using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IModerationListingReportQuery : IApplicationService
{
    Task<IReadOnlyList<ModerationListingReportDto>> GetAsync(CancellationToken cancellationToken = default);
}
