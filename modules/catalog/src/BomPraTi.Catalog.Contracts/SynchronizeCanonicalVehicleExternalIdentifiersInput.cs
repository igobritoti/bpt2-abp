namespace BomPraTi.Catalog.Contracts;

public sealed class SynchronizeCanonicalVehicleExternalIdentifiersInput
{
    public string Authority { get; set; } = string.Empty;
    public IReadOnlyList<CanonicalVehicleExternalIdentifierInput> Identifiers { get; set; } = Array.Empty<CanonicalVehicleExternalIdentifierInput>();
}

public sealed class CanonicalVehicleExternalIdentifierInput
{
    public string Namespace { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}
