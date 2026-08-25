using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class Generation : AggregateRoot<Guid>
{
    public Guid ModelId { get; private set; }
    public string Name { get; private set; } = null!;
    public int? StartYear { get; private set; }
    public int? EndYear { get; private set; }

    private Generation() { }

    public Generation(Guid id, Guid modelId, string name, int? startYear, int? endYear) : base(id)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Generation name is required.", nameof(name));
        if (startYear.HasValue && endYear.HasValue && startYear > endYear) throw new ArgumentException("Invalid generation year range.");
        ModelId = modelId;
        Name = name.Trim();
        StartYear = startYear;
        EndYear = endYear;
    }
}
