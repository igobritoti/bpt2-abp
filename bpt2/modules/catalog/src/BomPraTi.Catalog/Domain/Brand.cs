using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class Brand : AggregateRoot<Guid>
{
    public string Name { get; private set; } = null!;
    public string NormalizedName { get; private set; } = null!;

    private Brand() { }

    public Brand(Guid id, string name) : base(id)
    {
        Rename(name);
    }

    public void Rename(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Brand name is required.", nameof(name));
        Name = name.Trim();
        NormalizedName = Name.ToUpperInvariant();
    }
}
