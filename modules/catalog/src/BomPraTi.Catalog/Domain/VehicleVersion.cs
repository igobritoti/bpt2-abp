using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class VehicleVersion : AggregateRoot<Guid>
{
    public Guid ModelId { get; private set; }
    public Guid? GenerationId { get; private set; }
    public string Name { get; private set; } = null!;
    public string NormalizedName { get; private set; } = null!;

    private VehicleVersion() { }

    public VehicleVersion(Guid id, Guid modelId, Guid? generationId, string name) : base(id)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Version name is required.", nameof(name));
        ModelId = modelId;
        GenerationId = generationId;
        Name = name.Trim();
        NormalizedName = Name.ToUpperInvariant();
    }
}
