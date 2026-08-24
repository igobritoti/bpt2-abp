namespace BomPraTi.Ingestion.Contracts;

public sealed record IngestionRecordDto(
    Guid Id,
    string Source,
    string ExternalId,
    string RawIdentity,
    decimal Confidence,
    string Provenance,
    Guid? ReconciledVehicleId);
