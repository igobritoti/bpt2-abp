using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class VehicleModel : AggregateRoot<Guid>
{
    public Guid BrandId { get; private set; }
    public string Name { get; private set; } = null!;
    public string NormalizedName { get; private set; } = null!;

    private VehicleModel() { }

    public VehicleModel(Guid id, Guid brandId, string name) : base(id)
    {
        BrandId = brandId;
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Model name is required.", nameof(name));
        Name = name.Trim();
        NormalizedName = Name.ToUpperInvariant();
    }
}
