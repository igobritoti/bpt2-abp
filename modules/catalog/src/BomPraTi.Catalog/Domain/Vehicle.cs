using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class Vehicle : AggregateRoot<Guid>
{
    public Guid BrandId { get; private set; }
    public Guid ModelId { get; private set; }
    public Guid? GenerationId { get; private set; }
    public Guid VersionId { get; private set; }
    public int? ModelYear { get; private set; }
    public string? Powertrain { get; private set; }
    public string? Transmission { get; private set; }
    public string? BodyStyle { get; private set; }

    private Vehicle() { }

    public Vehicle(Guid id, Guid brandId, Guid modelId, Guid? generationId, Guid versionId, int? modelYear) : base(id)
    {
        BrandId = brandId;
        ModelId = modelId;
        GenerationId = generationId;
        VersionId = versionId;
        ModelYear = modelYear;
    }

    public void SynchronizeTechnicalIdentity(string? powertrain, string? transmission, string? bodyStyle)
    {
        Powertrain = powertrain;
        Transmission = transmission;
        BodyStyle = bodyStyle;
    }
}
