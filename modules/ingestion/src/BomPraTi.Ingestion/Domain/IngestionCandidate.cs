namespace BomPraTi.Ingestion.Domain;

public sealed record IngestionCandidate(
    string Source,
    string ExternalId,
    string RawIdentity,
    decimal Confidence,
    string Provenance)
{
    public IngestionCandidate Validate()
    {
        if (string.IsNullOrWhiteSpace(Source)) throw new ArgumentException("Source is required.");
        if (string.IsNullOrWhiteSpace(ExternalId)) throw new ArgumentException("ExternalId is required.");
        if (Confidence is < 0 or > 1) throw new ArgumentOutOfRangeException(nameof(Confidence));
        return this;
    }
}
