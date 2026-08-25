namespace BomPraTi.Catalog.Contracts;

public sealed class CreateCanonicalVehicleInput
{
    public string BrandName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public string? GenerationName { get; set; }
    public int? GenerationStartYear { get; set; }
    public int? GenerationEndYear { get; set; }
    public string VersionName { get; set; } = string.Empty;
    public int? ModelYear { get; set; }
}
