using Volo.Abp.Domain.Entities;

namespace BomPraTi.Catalog.Domain;

public sealed class VehicleExternalIdentifier : Entity<Guid>
{
    public Guid VehicleId { get; private set; }
    public string Authority { get; private set; } = string.Empty;
    public string Namespace { get; private set; } = string.Empty;
    public string Value { get; private set; } = string.Empty;

    private VehicleExternalIdentifier() { }

    public VehicleExternalIdentifier(Guid id, Guid vehicleId, string authority, string @namespace, string value) : base(id)
    {
        VehicleId = vehicleId;
        Authority = authority;
        Namespace = @namespace;
        Value = value;
    }
}
