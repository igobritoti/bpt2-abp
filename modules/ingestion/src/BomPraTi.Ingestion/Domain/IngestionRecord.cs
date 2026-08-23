using Volo.Abp.Domain.Entities;

namespace BomPraTi.Ingestion.Domain;

public sealed class IngestionRecord : AggregateRoot<Guid>
{
    public string Source { get; private set; } = null!;
    public string ExternalId { get; private set; } = null!;
    public string RawIdentity { get; private set; } = null!;
    public decimal Confidence { get; private set; }
    public string Provenance { get; private set; } = null!;
    public Guid? ReconciledVehicleId { get; private set; }

    private IngestionRecord() { }

    public IngestionRecord(Guid id, string source, string externalId, string rawIdentity, decimal confidence, string provenance) : base(id)
    {
        if (confidence is < 0 or > 1) throw new ArgumentOutOfRangeException(nameof(confidence));
        Source = source.Trim();
        ExternalId = externalId.Trim();
        RawIdentity = rawIdentity;
        Confidence = confidence;
        Provenance = provenance;
    }

    public void ReconcileTo(Guid vehicleId) => ReconciledVehicleId = vehicleId;
}
