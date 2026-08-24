using BomPraTi.Catalog.Contracts;
using BomPraTi.Ingestion.Contracts;
using BomPraTi.Ingestion.Data;
using BomPraTi.Ingestion.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;

namespace BomPraTi.Ingestion.Services;

[Authorize(Roles = "admin")]
public class IngestionCandidateAppService : IIngestionCandidateAppService, ITransientDependency
{
    private readonly IngestionDbContext _dbContext;
    private readonly IVehicleCatalogReader _vehicles;

    public IngestionCandidateAppService(
        IngestionDbContext dbContext,
        IVehicleCatalogReader vehicles)
    {
        _dbContext = dbContext;
        _vehicles = vehicles;
    }

    public async Task<IngestionRecordDto> CreateAsync(
        IngestionCandidateDto input,
        CancellationToken cancellationToken = default)
    {
        var candidate = new IngestionCandidate(
            input.Source,
            input.ExternalId,
            input.RawIdentity,
            input.Confidence,
            input.Provenance).Validate();

        var source = candidate.Source.Trim();
        var externalId = candidate.ExternalId.Trim();

        var existing = await _dbContext.Records
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.Source == source && x.ExternalId == externalId,
                cancellationToken);
        if (existing is not null)
        {
            return ToDto(existing);
        }

        var record = new IngestionRecord(
            Guid.NewGuid(),
            source,
            externalId,
            candidate.RawIdentity,
            candidate.Confidence,
            candidate.Provenance);

        await _dbContext.Records.AddAsync(record, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(record);
    }

    public async Task<IReadOnlyList<IngestionRecordDto>> GetPendingAsync(
        CancellationToken cancellationToken = default)
    {
        var records = await _dbContext.Records
            .AsNoTracking()
            .Where(x => x.ReconciledVehicleId == null)
            .OrderBy(x => x.Source)
            .ThenBy(x => x.ExternalId)
            .ThenBy(x => x.Id)
            .ToListAsync(cancellationToken);

        return records.Select(ToDto).ToList();
    }

    public async Task<IngestionRecordDto> ReconcileAsync(
        Guid recordId,
        Guid vehicleId,
        CancellationToken cancellationToken = default)
    {
        var record = await _dbContext.Records
            .SingleOrDefaultAsync(x => x.Id == recordId, cancellationToken)
            ?? throw new EntityNotFoundException<IngestionRecord>(recordId);

        if (await _vehicles.GetAsync(vehicleId, cancellationToken) is null)
        {
            throw new EntityNotFoundException(typeof(VehicleRefDto), vehicleId);
        }

        record.ReconcileTo(vehicleId);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(record);
    }

    private static IngestionRecordDto ToDto(IngestionRecord record) =>
        new(
            record.Id,
            record.Source,
            record.ExternalId,
            record.RawIdentity,
            record.Confidence,
            record.Provenance,
            record.ReconciledVehicleId);
}
