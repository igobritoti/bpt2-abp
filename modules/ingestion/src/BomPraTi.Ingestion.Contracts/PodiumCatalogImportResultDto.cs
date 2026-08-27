namespace BomPraTi.Ingestion.Contracts;

public sealed record PodiumCatalogImportResultDto(
    Guid VehicleId,
    string CanonicalExternalId,
    IReadOnlyList<string> RedirectsFrom,
    bool Replayed);
