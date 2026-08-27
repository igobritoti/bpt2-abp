using Volo.Abp.Application.Services;

namespace BomPraTi.Ingestion.Contracts;

public interface IPodiumCatalogFeedAppService : IApplicationService
{
    Task<PodiumCatalogImportResultDto> ImportAsync(
        PodiumCatalogVehicleInput input,
        CancellationToken cancellationToken = default);
}
