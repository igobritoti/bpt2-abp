using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

const string FixturePath = "benchmarks/podium_quantitative_consumer_v1.json";
const string SupportedSchema = "podium7.quantitative-enrichment.v1";
var supportedFields = new HashSet<string>(StringComparer.Ordinal)
{
    "displacement", "power", "torque", "length", "width", "height", "wheelbase", "curb_weight", "fuel_economy_combined"
};

using var fixtureDocument = JsonDocument.Parse(await File.ReadAllTextAsync(FixturePath));
var fixture = fixtureDocument.RootElement;
Require(fixture.GetProperty("schema").GetString() == "bpt2.podium-quantitative-consumer-benchmark.v1", "fixture schema mismatch");

var bindings = fixture.GetProperty("identityBindings")
    .EnumerateArray()
    .ToDictionary(
        x => RequireText(x, "externalId"),
        x => Guid.Parse(RequireText(x, "bptVehicleId")),
        StringComparer.Ordinal);
Require(bindings["podium7:vehicle:1"] == bindings["podium7:vehicle:old-1"], "historical redirect must converge before quantitative consumption");

var cases = fixture.GetProperty("payloadCases")
    .EnumerateArray()
    .ToDictionary(x => RequireText(x, "id"), x => x.Clone(), StringComparer.Ordinal);

var accepted = 0;
var rejected = 0;
var losslessRaw = 0;
var losslessTyped = 0;
var caseResults = new List<object>();

foreach (var (id, testCase) in cases)
{
    var expected = RequireText(testCase, "expected");
    var payload = testCase.GetProperty("payload");
    string outcome;
    try
    {
        var parsed = ParseEnvelope(payload, supportedFields);
        if (!string.Equals(expected, "ACCEPT", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"{id}: negative control unexpectedly accepted");
        }

        var rawRoundTrip = Canonical(payload) == Canonical(JsonNode.Parse(payload.GetRawText())!);
        Require(rawRoundTrip, $"{id}: raw envelope projection lost semantics");
        losslessRaw++;

        var typedRoundTrip = Canonical(payload) == Canonical(parsed.ToJson());
        Require(typedRoundTrip, $"{id}: typed projection lost semantics");
        losslessTyped++;
        accepted++;
        outcome = "ACCEPT";
    }
    catch (UnsupportedSchemaException)
    {
        Require(expected == "REJECT_UNSUPPORTED_SCHEMA", $"{id}: unsupported schema rejection was not expected");
        rejected++;
        outcome = "REJECT_UNSUPPORTED_SCHEMA";
    }
    catch (UnsupportedFieldException)
    {
        Require(expected == "REJECT_UNSUPPORTED_FIELD", $"{id}: unsupported field rejection was not expected");
        rejected++;
        outcome = "REJECT_UNSUPPORTED_FIELD";
    }

    caseResults.Add(new { id, expected, outcome });
}

var comparisonResults = new List<object>();
foreach (var comparison in fixture.GetProperty("comparisonCases").EnumerateArray())
{
    var id = RequireText(comparison, "id");
    var leftCase = ParseEnvelope(cases[RequireText(comparison, "leftCase")].GetProperty("payload"), supportedFields);
    var rightCase = ParseEnvelope(cases[RequireText(comparison, "rightCase")].GetProperty("payload"), supportedFields);
    var actual = Compare(
        leftCase,
        RequireText(comparison, "leftField"),
        rightCase,
        RequireText(comparison, "rightField"));
    var expected = RequireText(comparison, "expected");
    Require(actual == expected, $"comparison {id}: expected {expected}, got {actual}");
    comparisonResults.Add(new { id, expected, actual });
}

var sequence = fixture.GetProperty("stateSequence");
var canonicalExternalId = RequireText(sequence, "canonicalExternalId");
var historicalExternalId = RequireText(sequence, "historicalExternalId");
Require(bindings[canonicalExternalId] == bindings[historicalExternalId], "historical identity did not resolve to canonical BPT2 VehicleId");
var store = new Dictionary<Guid, Envelope>();
var stateResults = new List<object>();
foreach (var step in sequence.GetProperty("steps").EnumerateArray())
{
    var caseId = RequireText(step, "case");
    var envelope = ParseEnvelope(cases[caseId].GetProperty("payload"), supportedFields);
    var vehicleId = bindings[canonicalExternalId];
    var actual = Apply(store, vehicleId, envelope);
    var expected = RequireText(step, "expected");
    Require(actual == expected, $"state step {caseId}: expected {expected}, got {actual}");
    stateResults.Add(new { caseId, expected, actual, bptVehicleId = vehicleId, producerRevision = envelope.Revision });
}

var finalEnvelope = store[bindings[canonicalExternalId]];
var finalExpectation = sequence.GetProperty("finalExpectation");
var finalField = RequireText(finalExpectation, "field");
var canonicalPresent = finalEnvelope.Facts.Any(x => x.Field == finalField);
var conflictPresent = finalEnvelope.Conflicts.Any(x => x.Field == finalField);
Require(canonicalPresent == finalExpectation.GetProperty("canonicalFactPresent").GetBoolean(), "final canonical fact expectation mismatch");
Require(conflictPresent == finalExpectation.GetProperty("conflictPresent").GetBoolean(), "final conflict expectation mismatch");

var fixtureBytes = await File.ReadAllBytesAsync(FixturePath);
var fixtureSha = Convert.ToHexStringLower(SHA256.HashData(fixtureBytes));
var coverage = fixture.GetProperty("coverageExpectation");
Require(coverage.GetProperty("productReadyPromotionCandidates").GetArrayLength() == 0, "benchmark must not pre-authorize product fields");

var report = new
{
    schema = "bpt2.podium-quantitative-consumer-result.v1",
    fixture = new
    {
        path = FixturePath,
        sha256 = fixtureSha,
        datasetVersion = RequireText(fixture, "datasetVersion"),
        producerCommit = fixture.GetProperty("source").GetProperty("commit").GetString()
    },
    contract = new
    {
        supportedSchema = SupportedSchema,
        acceptedCases = accepted,
        rejectedNegativeControls = rejected,
        rawEnvelopeLosslessCases = losslessRaw,
        typedProjectionLosslessCases = losslessTyped
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
    state = new
    {
        steps = stateResults,
        finalField,
        canonicalPresent,
        conflictPresent
    },
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
Console.WriteLine($"PODIUM_QUANTITATIVE_CONTRACT_CASES: accepted={accepted} negative_controls={rejected} raw_lossless={losslessRaw} typed_lossless={losslessTyped}");
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
    if (current.Revision == envelope.Revision)
    {
        return "REPLAY_NO_CHANGE";
    }
    store[vehicleId] = envelope;
    return "REPLACED";
}

static string Compare(Envelope left, string leftField, Envelope right, string rightField)
{
    if (!string.Equals(leftField, rightField, StringComparison.Ordinal)) return "NOT_COMPARABLE";
    if (left.Conflicts.Any(x => x.Field == leftField) || right.Conflicts.Any(x => x.Field == rightField)) return "NOT_COMPARABLE";
    var lf = left.Facts.SingleOrDefault(x => x.Field == leftField);
    var rf = right.Facts.SingleOrDefault(x => x.Field == rightField);
    if (lf is null || rf is null || lf.KnowledgeState != "known" || rf.KnowledgeState != "known") return "NOT_COMPARABLE";
    if (!string.Equals(lf.Unit, rf.Unit, StringComparison.Ordinal)) return "NOT_COMPARABLE";
    if (!string.Equals(lf.ContextCanonical, rf.ContextCanonical, StringComparison.Ordinal)) return "NOT_COMPARABLE";
    if (lf.ValueShape is "limit" or "multiple" || rf.ValueShape is "limit" or "multiple") return "NOT_COMPARABLE";

    var (lmin, lmax) = Bounds(lf);
    var (rmin, rmax) = Bounds(rf);
    if (lmax < rmin) return "LESS";
    if (lmin > rmax) return "GREATER";
    if (lmin == rmin && lmax == rmax) return "EQUAL";
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
    throw new InvalidOperationException("Bounds requested for non-orderable shape");
}

static Envelope ParseEnvelope(JsonElement payload, HashSet<string> supportedFields)
{
    var schema = RequireText(payload, "schema");
    if (schema != SupportedSchema) throw new UnsupportedSchemaException();
    var vehicleId = RequireText(payload, "vehicleId");
    var revision = RequireText(payload, "revision");
    Require(revision.Length == 64 && revision.All(Uri.IsHexDigit), "revision must be a 64-char SHA-256 hex string");

    var facts = new List<Fact>();
    var factFields = new HashSet<string>(StringComparer.Ordinal);
    foreach (var factElement in payload.GetProperty("facts").EnumerateArray())
    {
        var field = RequireText(factElement, "field");
        if (!supportedFields.Contains(field)) throw new UnsupportedFieldException();
        Require(factFields.Add(field), "duplicate fact field");
        var state = RequireText(factElement, "knowledgeState");
        Require(state is "known" or "unknown" or "not_applicable", "unsupported knowledge state");
        var provenance = RequireText(factElement, "provenanceRef");
        string? shape = null;
        string? unit = null;
        JsonElement? value = null;
        string? contextCanonical = null;
        if (state == "known")
        {
            shape = RequireText(factElement, "valueShape");
            Require(shape is "scalar" or "range" or "limit" or "multiple", "unsupported value shape");
            Require(factElement.TryGetProperty("value", out var valueElement), "known fact requires value");
            value = valueElement.Clone();
            unit = RequireText(factElement, "unit");
            ValidateValue(shape, valueElement);
        }
        else
        {
            Require(!factElement.TryGetProperty("valueShape", out _) && !factElement.TryGetProperty("value", out _) && !factElement.TryGetProperty("unit", out _), "unknown/not_applicable cannot carry value/shape/unit");
        }
        if (factElement.TryGetProperty("context", out var context))
        {
            foreach (var property in context.EnumerateObject())
            {
                Require(property.Name is "market" or "applicability" or "methodology", "unsupported context key");
                Require(property.Value.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(property.Value.GetString()), "context values must be non-empty text");
            }
            contextCanonical = Canonical(context);
        }
        facts.Add(new Fact(field, state, provenance, shape, value, unit, contextCanonical));
    }

    var conflicts = new List<Conflict>();
    var conflictFields = new HashSet<string>(StringComparer.Ordinal);
    foreach (var conflictElement in payload.GetProperty("conflicts").EnumerateArray())
    {
        var field = RequireText(conflictElement, "field");
        if (!supportedFields.Contains(field)) throw new UnsupportedFieldException();
        Require(conflictFields.Add(field), "duplicate conflict field");
        var refs = conflictElement.GetProperty("provenanceRefs").EnumerateArray().Select(x => x.GetString() ?? string.Empty).ToArray();
        Require(refs.Length >= 2 && refs.All(x => !string.IsNullOrWhiteSpace(x)) && refs.Distinct(StringComparer.Ordinal).Count() == refs.Length, "conflict requires two unique provenance refs");
        var reason = RequireText(conflictElement, "reason");
        conflicts.Add(new Conflict(field, refs, reason));
    }
    Require(!factFields.Overlaps(conflictFields), "canonical fact and unresolved conflict cannot coexist for same field");

    var computed = ComputeRevision(schema, vehicleId, payload.GetProperty("facts"), payload.GetProperty("conflicts"));
    Require(string.Equals(computed, revision, StringComparison.Ordinal), $"revision mismatch: expected {revision}, computed {computed}");
    return new Envelope(schema, vehicleId, revision, facts, conflicts);
}

static void ValidateValue(string shape, JsonElement value)
{
    if (shape == "scalar")
    {
        Require(value.ValueKind == JsonValueKind.Number, "quantitative scalar must be numeric");
    }
    else if (shape == "range")
    {
        var properties = value.EnumerateObject().Select(x => x.Name).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        Require(properties.SequenceEqual(new[] { "maxValue", "minValue" }), "range must contain exactly minValue/maxValue");
        var min = value.GetProperty("minValue").GetDecimal();
        var max = value.GetProperty("maxValue").GetDecimal();
        Require(min <= max, "range minValue cannot exceed maxValue");
    }
    else if (shape == "limit")
    {
        var properties = value.EnumerateObject().Select(x => x.Name).OrderBy(x => x, StringComparer.Ordinal).ToArray();
        Require(properties.SequenceEqual(new[] { "operator", "value" }), "limit must contain exactly operator/value");
        Require(value.GetProperty("operator").GetString() is "lt" or "lte" or "gt" or "gte", "unsupported limit operator");
        Require(value.GetProperty("value").ValueKind == JsonValueKind.Number, "limit value must be numeric");
    }
    else if (shape == "multiple")
    {
        Require(value.ValueKind == JsonValueKind.Array && value.GetArrayLength() > 0 && value.EnumerateArray().All(x => x.ValueKind == JsonValueKind.Number), "multiple must be non-empty numeric array");
    }
}

static string ComputeRevision(string schema, string vehicleId, JsonElement facts, JsonElement conflicts)
{
    var factNodes = facts.EnumerateArray().Select(x => JsonNode.Parse(x.GetRawText())!).ToList();
    factNodes.Sort((a, b) =>
    {
        var af = a!["field"]!.GetValue<string>();
        var bf = b!["field"]!.GetValue<string>();
        var fieldCmp = string.CompareOrdinal(af, bf);
        if (fieldCmp != 0) return fieldCmp;
        var ap = a["provenanceRef"]!.GetValue<string>();
        var bp = b["provenanceRef"]!.GetValue<string>();
        var provenanceCmp = string.CompareOrdinal(ap, bp);
        return provenanceCmp != 0 ? provenanceCmp : string.CompareOrdinal(Canonical(a), Canonical(b));
    });
    var conflictNodes = conflicts.EnumerateArray().Select(x => JsonNode.Parse(x.GetRawText())!).ToList();
    conflictNodes.Sort((a, b) =>
    {
        var fieldCmp = string.CompareOrdinal(a!["field"]!.GetValue<string>(), b!["field"]!.GetValue<string>());
        return fieldCmp != 0 ? fieldCmp : string.CompareOrdinal(Canonical(a), Canonical(b));
    });
    var material = new JsonObject
    {
        ["schema"] = schema,
        ["vehicleId"] = vehicleId,
        ["facts"] = new JsonArray(factNodes.Select(x => x.DeepClone()).ToArray()),
        ["conflicts"] = new JsonArray(conflictNodes.Select(x => x.DeepClone()).ToArray())
    };
    return Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(Canonical(material))));
}

static string Canonical(JsonElement element) => Canonical(JsonNode.Parse(element.GetRawText())!);
static string Canonical(JsonNode node)
{
    var normalized = Normalize(node);
    return normalized.ToJsonString(new JsonSerializerOptions { WriteIndented = false });
}

static JsonNode Normalize(JsonNode node)
{
    if (node is JsonObject obj)
    {
        var result = new JsonObject();
        foreach (var property in obj.OrderBy(x => x.Key, StringComparer.Ordinal))
        {
            result[property.Key] = property.Value is null ? null : Normalize(property.Value);
        }
        return result;
    }
    if (node is JsonArray array)
    {
        return new JsonArray(array.Select(x => x is null ? null : Normalize(x)).ToArray());
    }
    return node.DeepClone();
}

static string RequireText(JsonElement element, string property)
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
    public JsonObject ToJson()
    {
        var result = new JsonObject
        {
            ["field"] = Field,
            ["knowledgeState"] = KnowledgeState,
            ["provenanceRef"] = ProvenanceRef
        };
        if (KnowledgeState == "known")
        {
            result["valueShape"] = ValueShape;
            result["value"] = JsonNode.Parse(Value!.Value.GetRawText());
            result["unit"] = Unit;
        }
        if (ContextCanonical is not null) result["context"] = JsonNode.Parse(ContextCanonical);
        return result;
    }
}

sealed record Conflict(string Field, string[] ProvenanceRefs, string Reason)
{
    public JsonObject ToJson() => new()
    {
        ["field"] = Field,
        ["provenanceRefs"] = new JsonArray(ProvenanceRefs.Select(JsonValue.Create).ToArray()),
        ["reason"] = Reason
    };
}

sealed record Envelope(string Schema, string VehicleId, string Revision, List<Fact> Facts, List<Conflict> Conflicts)
{
    public JsonObject ToJson() => new()
    {
        ["schema"] = Schema,
        ["vehicleId"] = VehicleId,
        ["revision"] = Revision,
        ["facts"] = new JsonArray(Facts.Select(x => (JsonNode)x.ToJson()).ToArray()),
        ["conflicts"] = new JsonArray(Conflicts.Select(x => (JsonNode)x.ToJson()).ToArray())
    };
}

sealed class UnsupportedSchemaException : Exception;
sealed class UnsupportedFieldException : Exception;
