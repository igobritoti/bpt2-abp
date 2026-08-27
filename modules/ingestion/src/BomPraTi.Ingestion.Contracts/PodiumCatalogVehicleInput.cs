namespace BomPraTi.Ingestion.Contracts;

public sealed class PodiumCatalogVehicleInput
{
    public string ContractVersion { get; set; } = string.Empty;
    public PodiumCatalogEntityInput Entity { get; set; } = new();
    public IReadOnlyList<string> RedirectsFrom { get; set; } = Array.Empty<string>();
}

public sealed class PodiumCatalogEntityInput
{
    public string Id { get; set; } = string.Empty;
    public string Make { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string? Generation { get; set; }
    public string? Variant { get; set; }
    public string? Powertrain { get; set; }
    public string? Transmission { get; set; }
    public string? BodyStyle { get; set; }
    public string? Market { get; set; }
    public int? ManufactureYearFrom { get; set; }
    public int? ManufactureYearTo { get; set; }
    public int? ModelYearFrom { get; set; }
    public int? ModelYearTo { get; set; }
    public IReadOnlyList<string> Aliases { get; set; } = Array.Empty<string>();
    public IReadOnlyList<string> EngineIdentifiers { get; set; } = Array.Empty<string>();
    public IReadOnlyList<PodiumExternalIdentifierInput> ExternalIdentifiers { get; set; } = Array.Empty<PodiumExternalIdentifierInput>();
}

public sealed class PodiumExternalIdentifierInput
{
    public string Namespace { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}
