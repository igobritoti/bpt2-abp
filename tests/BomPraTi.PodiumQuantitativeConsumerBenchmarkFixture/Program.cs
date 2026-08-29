using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

const string FixturePath = "benchmarks/podium_quantitative_consumer_v1.json";
const string SupportedSchema = "podium7.quantitative-enrichment.v1";
var supportedFields = new HashSet<string>(StringComparer.Ordinal)
{
    "displacement", "power", "torque", "length", "width", "height", "wheelbase", "curb_weight", "fuel_economy_combined"
};

using var fixtureDocument = JsonDocument.Parse(await File.ReadAllTextAsync(FixturePath));
var fixture = fixtureDocument.RootElement;
Require(Text(fixture, "schema") == "bpt2.podium-quantitative-consumer-benchmark.v1", "fixture schema mismatch");

var bindings = fixture.GetProperty("identityBindings").EnumerateArray().ToDictionary(
    x => Text(x, "externalId"),
    x => Guid.Parse(Text(x, "bptVehicleId")),
    StringComparer.Ordinal);
Require(bindings["podium7:vehicle:1"] == bindings["podium7:vehicle:old-1"], "historical redirect must converge before quantitative consumption");

var cases = fixture.GetProperty("payloadCases").EnumerateArray().ToDictionary(
    x => Text(x, "id"), x => x.Clone(), StringComparer.Ordinal);

var accepted = 0;
var rejected = 0;
var rawLossless = 0;
var typedLossless = 0;
var caseResults = new List<object>();

foreach (var (id, item) in cases)
{
    var expected = Text(item, "expected");
    var payload = item.GetProperty("payload");
    string outcome;
    try
    {
        var envelope = ParseEnvelope(payload, supportedFields);
        Require(expected == "ACCEPT", $"{id}: negative control unexpectedly accepted");
        Require(Canonical(payload) == Canonical(JsonDocument.Parse(payload.GetRawText()).RootElement), $"{id}: raw projection lost semantics");
        rawLossless++;
        Require(Canonical(payload) == envelope.CanonicalJson(), $"{id}: typed projection lost semantics");
        typedLossless++;
        accepted++;
        outcome = "ACCEPT";
    }
    catch (UnsupportedSchemaException)
    {
        Require(expected == "REJECT_UNSUPPORTED_SCHEMA", $"{id}: unexpected unsupported-schema rejection");
        rejected++;
        outcome = "REJECT_UNSUPPORTED_SCHEMA";
    }
    catch (UnsupportedFieldException)
    {
        Require(expected == "REJECT_UNSUPPORTED_FIELD", $"{id}: unexpected unsupported-field rejection");
        rejected++;
        outcome = "REJECT_UNSUPPORTED_FIELD";
    }
    caseResults.Add(new { id, expected, outcome });
}

var comparisonResults = new List<object>();
foreach (var item in fixture.GetProperty("comparisonCases").EnumerateArray())
{
    var id = Text(item, "id");
    var left = ParseEnvelope(cases[Text(item, "leftCase")].GetProperty("payload"), supportedFields);
    var right = ParseEnvelope(cases[Text(item, "rightCase")].GetProperty("payload"), supportedFields);
    var actual = Compare(left, Text(item, "leftField"), right, Text(item, "rightField"));
    var expected = Text(item, "expected");
    Require(actual == expected, $"comparison {id}: expected {expected}, got {actual}");
    comparisonResults.Add(new { id, expected, actual });
}

var sequence = fixture.GetProperty("stateSequence");
var canonicalExternalId = Text(sequence, "canonicalExternalId");
var historicalExternalId = Text(sequence, "historicalExternalId");
Require(bindings[canonicalExternalId] == bindings[historicalExternalId], "historical redirect did not converge to canonical BPT2 VehicleId");
var store = new Dictionary<Guid, Envelope>();
var stateResults = new List<object>();
foreach (var step in sequence.GetProperty("steps").EnumerateArray())
{
    var caseId = Text(step, "case");
    var envelope = ParseEnvelope(cases[caseId].GetProperty("payload"), supportedFields);
    var bptVehicleId = bindings[canonicalExternalId];
    var actual = Apply(store, bptVehicleId, envelope);
    var expected = Text(step, "expected");
    Require(actual == expected, $"state {caseId}: expected {expected}, got {actual}");
    stateResults.Add(new { caseId, expected, actual, bptVehicleId, producerRevision = envelope.Revision });
}

var finalState = store[bindings[canonicalExternalId]];
var finalExpectation = sequence.GetProperty("finalExpectation");
var finalField = Text(finalExpectation, "field");
var canonicalPresent = finalState.Facts.Any(x => x.Field == finalField);
var conflictPresent = finalState.Conflicts.Any(x => x.Field == finalField);
Require(canonicalPresent == finalExpectation.GetProperty("canonicalFactPresent").GetBoolean(), "final canonical fact mismatch");
Require(conflictPresent == finalExpectation.GetProperty("conflictPresent").GetBoolean(), "final conflict mismatch");

var coverage = fixture.GetProperty("coverageExpectation");
Require(coverage.GetProperty("productReadyPromotionCandidates").GetArrayLength() == 0, "fixture must not pre-authorize product fields");
var fixtureSha = Convert.ToHexStringLower(SHA256.HashData(await File.ReadAllBytesAsync(FixturePath)));
var report = new
{
    schema = "bpt2.podium-quantitative-consumer-result.v1",
    fixture = new
    {
        path = FixturePath,
        sha256 = fixtureSha,
        datasetVersion = Text(fixture, "datasetVersion"),
        producerCommit = fixture.GetProperty("source").GetProperty("commit").GetString()
    },
    contract = new
    {
        supportedSchema = SupportedSchema,
        acceptedCases = accepted,
        rejectedNegativeControls = rejected,
        rawEnvelopeLosslessCases = rawLossless,
        typedProjectionLosslessCases = typedLossless
    },
    identity = new
    {
        canonicalExternalId,
        historicalExternalId,
        convergedBptVehicleId = bindings[canonicalExternalId],
        quantitativeFactsUsedForIdentityResolution = false
    },
    comparability = new
    {
        cases = comparisonResults,
        unitConversionInferred = false,
        contextMismatchComparable = false,
        limitOrderingAuthorized = false,
        multipleOrderingAuthorized = false
    },
    state = new { steps = stateResults, finalField, canonicalPresent, conflictPresent },
    coverage = new
    {
        evidenceBackedFields = coverage.GetProperty("evidenceBackedFields").EnumerateArray().Select(x => x.GetString()).ToArray(),
        evidenceBackedShapes = coverage.GetProperty("evidenceBackedShapes").EnumerateArray().Select(x => x.GetString()).ToArray(),
        contractShapeOnly = coverage.GetProperty("contractShapeOnly").EnumerateArray().Select(x => x.GetString()).ToArray(),
        productReadyPromotionCandidates = Array.Empty<string>()
    },
    disposition = new
    {
        consumerShapeReadiness = "PROVED_BOUNDED",
        semanticLoss = 0,
        productCoverage = "INSUFFICIENT",
        comparatorUi = "STILL_BLOCKED",
        pbev = "STILL_UPSTREAM_GATED"
    },
    caseResults
};

var outputPath = Environment.GetEnvironmentVariable("BPT_QUANTITATIVE_BENCHMARK_OUTPUT") ?? "artifacts/podium-quantitative-consumer-benchmark.json";
Directory.CreateDirectory(Path.GetDirectoryName(outputPath) ?? ".");
await File.WriteAllTextAsync(outputPath, JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine($"PODIUM_QUANTITATIVE_FIXTURE_SHA256: {fixtureSha}");
Console.WriteLine($"PODIUM_QUANTITATIVE_CONTRACT_CASES: accepted={accepted} negative_controls={rejected} raw_lossless={rawLossless} typed_lossless={typedLossless}");
Console.WriteLine($"PODIUM_QUANTITATIVE_COMPARISON_CASES: PASS ({comparisonResults.Count}/{comparisonResults.Count})");
Console.WriteLine("PODIUM_QUANTITATIVE_IDENTITY_REDIRECT: PASS");
Console.WriteLine("PODIUM_QUANTITATIVE_STATE_SEQUENCE: PASS");
Console.WriteLine("PODIUM_QUANTITATIVE_PRODUCT_PROMOTION: NONE");
Console.WriteLine($"PODIUM_QUANTITATIVE_BENCHMARK_ARTIFACT: {outputPath}");

static string Apply(Dictionary<Guid, Envelope> store, Guid vehicleId, Envelope envelope)
{
    if (!store.TryGetValue(vehicleId, out var current))
    {
        store[vehicleId] = envelope;
        return "CREATED";
    }
    if (current.Revision == envelope.Revision) return "REPLAY_NO_CHANGE";
    store[vehicleId] = envelope;
    return "REPLACED";
}

static string Compare(Envelope left, string leftField, Envelope right, string rightField)
{
    if (leftField != rightField) return "NOT_COMPARABLE";
    if (left.Conflicts.Any(x => x.Field == leftField) || right.Conflicts.Any(x => x.Field == rightField)) return "NOT_COMPARABLE";
    var a = left.Facts.SingleOrDefault(x => x.Field == leftField);
    var b = right.Facts.SingleOrDefault(x => x.Field == rightField);
    if (a is null || b is null || a.KnowledgeState != "known" || b.KnowledgeState != "known") return "NOT_COMPARABLE";
    if (a.Unit != b.Unit || a.ContextCanonical != b.ContextCanonical) return "NOT_COMPARABLE";
    if (a.ValueShape is "limit" or "multiple" || b.ValueShape is "limit" or "multiple") return "NOT_COMPARABLE";
    var (amin, amax) = Bounds(a);
    var (bmin, bmax) = Bounds(b);
    if (amax < bmin) return "LESS";
    if (amin > bmax) return "GREATER";
    if (amin == bmin && amax == bmax) return "EQUAL";
    return "NOT_ORDERABLE";
}

static (decimal Min, decimal Max) Bounds(Fact fact)
{
    if (fact.ValueShape == "scalar")
    {
        var value = fact.Value!.Value.GetDecimal();
        return (value, value);
    }
    if (fact.ValueShape == "range")
    {
        var value = fact.Value!.Value;
        return (value.GetProperty("minValue").GetDecimal(), value.GetProperty("maxValue").GetDecimal());
    }
    throw new InvalidOperationException("bounds unavailable for non-orderable shape");
}

static Envelope ParseEnvelope(JsonElement payload, HashSet<string> supportedFields)
{
    var schema = Text(payload, "schema");
    if (schema != SupportedSchema) throw new UnsupportedSchemaException();
    var vehicleId = Text(payload, "vehicleId");
    var revision = Text(payload, "revision");
    Require(revision.Length == 64 && revision.All(Uri.IsHexDigit), "revision must be SHA-256 hex");

    var facts = new List<Fact>();
    var factFields = new HashSet<string>(StringComparer.Ordinal);
    foreach (var source in payload.GetProperty("facts").EnumerateArray())
    {
        var field = Text(source, "field");
        if (!supportedFields.Contains(field)) throw new UnsupportedFieldException();
        Require(factFields.Add(field), "duplicate fact field");
        var state = Text(source, "knowledgeState");
        Require(state is "known" or "unknown" or "not_applicable", "unsupported knowledge state");
        var provenance = Text(source, "provenanceRef");
        string? shape = null;
        string? unit = null;
        JsonElement? value = null;
        string? contextCanonical = null;
        if (state == "known")
        {
            shape = Text(source, "valueShape");
            Require(shape is "scalar" or "range" or "limit" or "multiple", "unsupported value shape");
            Require(source.TryGetProperty("value", out var valueElement), "known fact requires value");
            ValidateValue(shape, valueElement);
            value = valueElement.Clone();
            unit = Text(source, "unit");
        }
        else
        {
            Require(!source.TryGetProperty("valueShape", out _) && !source.TryGetProperty("value", out _) && !source.TryGetProperty("unit", out _), "unknown/not_applicable cannot carry value/shape/unit");
        }
        if (source.TryGetProperty("context", out var context))
        {
            foreach (var property in context.EnumerateObject())
            {
                Require(property.Name is "market" or "applicability" or "methodology", "unsupported context key");
                Require(property.Value.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(property.Value.GetString()), "context value must be non-empty text");
            }
            contextCanonical = Canonical(context);
        }
        facts.Add(new Fact(field, state, provenance, shape, value, unit, contextCanonical));
    }

    var conflicts = new List<Conflict>();
    var conflictFields = new HashSet<string>(StringComparer.Ordinal);
    foreach (var source in payload.GetProperty("conflicts").EnumerateArray())
    {
        var field = Text(source, "field");
        if (!supportedFields.Contains(field)) throw new UnsupportedFieldException();
        Require(conflictFields.Add(field), "duplicate conflict field");
        var refs = source.GetProperty("provenanceRefs").EnumerateArray().Select(x => x.GetString() ?? string.Empty).ToArray();
        Require(refs.Length >= 2 && refs.All(x => !string.IsNullOrWhiteSpace(x)) && refs.Distinct(StringComparer.Ordinal).Count() == refs.Length, "conflict requires unique provenance refs");
        conflicts.Add(new Conflict(field, refs, Text(source, "reason")));
    }
    Require(!factFields.Overlaps(conflictFields), "fact and unresolved conflict cannot coexist for same field");
    Require(ComputeRevision(schema, vehicleId, payload.GetProperty("facts"), payload.GetProperty("conflicts")) == revision, "producer revision mismatch");
    return new Envelope(schema, vehicleId, revision, facts, conflicts);
}

static void ValidateValue(string shape, JsonElement value)
{
    if (shape == "scalar")
    {
        Require(value.ValueKind == JsonValueKind.Number, "scalar must be numeric");
        return;
    }
    if (shape == "range")
    {
        Require(value.ValueKind == JsonValueKind.Object, "range must be object");
        var names = value.EnumerateObject().Select(x => x.Name).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        Require(names.SequenceEqual(new[] { "maxValue", "minValue" }), "range must contain exactly minValue/maxValue");
        Require(value.GetProperty("minValue").GetDecimal() <= value.GetProperty("maxValue").GetDecimal(), "reversed range");
        return;
    }
    if (shape == "limit")
    {
        Require(value.ValueKind == JsonValueKind.Object, "limit must be object");
        var names = value.EnumerateObject().Select(x => x.Name).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        Require(names.SequenceEqual(new[] { "operator", "value" }), "limit must contain exactly operator/value");
        Require(value.GetProperty("operator").GetString() is "lt" or "lte" or "gt" or "gte", "unsupported limit operator");
        Require(value.GetProperty("value").ValueKind == JsonValueKind.Number, "limit value must be numeric");
        return;
    }
    Require(shape == "multiple" && value.ValueKind == JsonValueKind.Array && value.GetArrayLength() > 0 && value.EnumerateArray().All(x => x.ValueKind == JsonValueKind.Number), "multiple must be non-empty numeric array");
}

static string ComputeRevision(string schema, string vehicleId, JsonElement facts, JsonElement conflicts)
{
    var factStrings = facts.EnumerateArray().Select(x => new
    {
        Field = Text(x, "field"),
        Provenance = Text(x, "provenanceRef"),
        Canonical = Canonical(x)
    }).OrderBy(x => x.Field, StringComparer.Ordinal).ThenBy(x => x.Provenance, StringComparer.Ordinal).ThenBy(x => x.Canonical, StringComparer.Ordinal).Select(x => x.Canonical).ToArray();
    var conflictStrings = conflicts.EnumerateArray().Select(x => new { Field = Text(x, "field"), Canonical = Canonical(x) })
        .OrderBy(x => x.Field, StringComparer.Ordinal).ThenBy(x => x.Canonical, StringComparer.Ordinal).Select(x => x.Canonical).ToArray();
    var material = "{\"conflicts\":[" + string.Join(',', conflictStrings) + "],\"facts\":[" + string.Join(',', factStrings) + "],\"schema\":" + JsonSerializer.Serialize(schema) + ",\"vehicleId\":" + JsonSerializer.Serialize(vehicleId) + "}";
    return Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(material)));
}

static string Canonical(JsonElement element)
{
    return element.ValueKind switch
    {
        JsonValueKind.Object => "{" + string.Join(',', element.EnumerateObject().OrderBy(x => x.Name, StringComparer.Ordinal).Select(x => JsonSerializer.Serialize(x.Name) + ":" + Canonical(x.Value))) + "}",
        JsonValueKind.Array => "[" + string.Join(',', element.EnumerateArray().Select(Canonical)) + "]",
        JsonValueKind.String => JsonSerializer.Serialize(element.GetString()),
        JsonValueKind.Number => element.GetRawText(),
        JsonValueKind.True => "true",
        JsonValueKind.False => "false",
        JsonValueKind.Null => "null",
        _ => throw new InvalidOperationException("unsupported JSON token")
    };
}

static string Text(JsonElement element, string property)
{
    Require(element.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(value.GetString()), $"{property} must be non-empty text");
    return value.GetString()!;
}

static void Require(bool condition, string message)
{
    if (!condition) throw new InvalidOperationException(message);
}

sealed record Fact(string Field, string KnowledgeState, string ProvenanceRef, string? ValueShape, JsonElement? Value, string? Unit, string? ContextCanonical)
{
    public string CanonicalJson()
    {
        var entries = new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["field"] = JsonSerializer.Serialize(Field),
            ["knowledgeState"] = JsonSerializer.Serialize(KnowledgeState),
            ["provenanceRef"] = JsonSerializer.Serialize(ProvenanceRef)
        };
        if (KnowledgeState == "known")
        {
            entries["unit"] = JsonSerializer.Serialize(Unit);
            entries["value"] = ProgramCanonical(Value!.Value);
            entries["valueShape"] = JsonSerializer.Serialize(ValueShape);
        }
        if (ContextCanonical is not null) entries["context"] = ContextCanonical;
        return "{" + string.Join(',', entries.Select(x => JsonSerializer.Serialize(x.Key) + ":" + x.Value)) + "}";
    }

    private static string ProgramCanonical(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Object => "{" + string.Join(',', element.EnumerateObject().OrderBy(x => x.Name, StringComparer.Ordinal).Select(x => JsonSerializer.Serialize(x.Name) + ":" + ProgramCanonical(x.Value))) + "}",
            JsonValueKind.Array => "[" + string.Join(',', element.EnumerateArray().Select(ProgramCanonical)) + "]",
            JsonValueKind.String => JsonSerializer.Serialize(element.GetString()),
            JsonValueKind.Number => element.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Null => "null",
            _ => throw new InvalidOperationException("unsupported JSON token")
        };
    }
}

sealed record Conflict(string Field, string[] ProvenanceRefs, string Reason)
{
    public string CanonicalJson()
    {
        var refs = "[" + string.Join(',', ProvenanceRefs.Select(x => JsonSerializer.Serialize(x))) + "]";
        return "{\"field\":" + JsonSerializer.Serialize(Field) + ",\"provenanceRefs\":" + refs + ",\"reason\":" + JsonSerializer.Serialize(Reason) + "}";
    }
}

sealed record Envelope(string Schema, string VehicleId, string Revision, List<Fact> Facts, List<Conflict> Conflicts)
{
    public string CanonicalJson()
    {
        return "{\"conflicts\":[" + string.Join(',', Conflicts.Select(x => x.CanonicalJson())) + "],\"facts\":[" + string.Join(',', Facts.Select(x => x.CanonicalJson())) + "],\"revision\":" + JsonSerializer.Serialize(Revision) + ",\"schema\":" + JsonSerializer.Serialize(Schema) + ",\"vehicleId\":" + JsonSerializer.Serialize(VehicleId) + "}";
    }
}

sealed class UnsupportedSchemaException : Exception;
sealed class UnsupportedFieldException : Exception;
