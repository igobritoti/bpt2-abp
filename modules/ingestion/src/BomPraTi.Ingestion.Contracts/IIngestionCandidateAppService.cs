using Volo.Abp.Application.Services;

namespace BomPraTi.Ingestion.Contracts;

public interface IIngestionCandidateAppService : IApplicationService
{
    Task<IngestionRecordDto> CreateAsync(
        IngestionCandidateDto input,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<IngestionRecordDto>> GetPendingAsync(
        CancellationToken cancellationToken = default);

    Task<IngestionRecordDto> ReconcileAsync(
        Guid recordId,
        Guid vehicleId,
        CancellationToken cancellationToken = default);
}
