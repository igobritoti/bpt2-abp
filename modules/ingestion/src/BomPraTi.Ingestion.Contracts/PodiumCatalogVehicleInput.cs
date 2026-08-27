using System.Text.Json.Serialization;

namespace BomPraTi.Ingestion.Contracts;

public sealed class PodiumCatalogVehicleInput
{
    [JsonPropertyName("contractVersion")]
    public string ContractVersion { get; set; } = string.Empty;

    [JsonPropertyName("entity")]
    public PodiumCatalogEntityInput Entity { get; set; } = new();

    [JsonPropertyName("redirectsFrom")]
    public IReadOnlyList<string> RedirectsFrom { get; set; } = Array.Empty<string>();
}

public sealed class PodiumCatalogEntityInput
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("make")]
    public string Make { get; set; } = string.Empty;

    [JsonPropertyName("model")]
    public string Model { get; set; } = string.Empty;

    [JsonPropertyName("generation")]
    public string? Generation { get; set; }

    [JsonPropertyName("variant")]
    public string? Variant { get; set; }

    [JsonPropertyName("powertrain")]
    public string? Powertrain { get; set; }

    [JsonPropertyName("transmission")]
    public string? Transmission { get; set; }

    [JsonPropertyName("body_style")]
    public string? BodyStyle { get; set; }

    [JsonPropertyName("market")]
    public string? Market { get; set; }

    [JsonPropertyName("manufacture_year_from")]
    public int? ManufactureYearFrom { get; set; }

    [JsonPropertyName("manufacture_year_to")]
    public int? ManufactureYearTo { get; set; }

    [JsonPropertyName("model_year_from")]
    public int? ModelYearFrom { get; set; }

    [JsonPropertyName("model_year_to")]
    public int? ModelYearTo { get; set; }

    [JsonPropertyName("aliases")]
    public IReadOnlyList<string> Aliases { get; set; } = Array.Empty<string>();

    [JsonPropertyName("engine_identifiers")]
    public IReadOnlyList<string> EngineIdentifiers { get; set; } = Array.Empty<string>();

    [JsonPropertyName("external_identifiers")]
    public IReadOnlyList<PodiumExternalIdentifierInput> ExternalIdentifiers { get; set; } = Array.Empty<PodiumExternalIdentifierInput>();
}

public sealed class PodiumExternalIdentifierInput
{
    [JsonPropertyName("namespace")]
    public string Namespace { get; set; } = string.Empty;

    [JsonPropertyName("value")]
    public string Value { get; set; } = string.Empty;
}
