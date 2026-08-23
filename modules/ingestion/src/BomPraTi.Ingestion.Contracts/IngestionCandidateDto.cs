namespace BomPraTi.Ingestion.Contracts;

public sealed record IngestionCandidateDto(
    string Source,
    string ExternalId,
    string RawIdentity,
    decimal Confidence,
    string Provenance);
