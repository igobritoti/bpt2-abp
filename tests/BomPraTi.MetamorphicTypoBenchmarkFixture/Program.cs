using System.Data.Common;
using System.Diagnostics;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
}

var baselinePath = Environment.GetEnvironmentVariable("BPT_DISCOVERY_BENCHMARK_OUTPUT");
if (string.IsNullOrWhiteSpace(baselinePath) || !File.Exists(baselinePath))
{
    throw new InvalidOperationException("BPT_DISCOVERY_BENCHMARK_OUTPUT must point to the executed discovery baseline artifact.");
}

var fixturePath = Path.Combine(AppContext.BaseDirectory, "benchmarks", "discovery_br_v1.json");
var fixtureBytes = await File.ReadAllBytesAsync(fixturePath);
var fixtureSha256 = Convert.ToHexString(SHA256.HashData(fixtureBytes)).ToLowerInvariant();
var fixture = JsonSerializer.Deserialize<DiscoveryFixture>(
    fixtureBytes,
    new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
    ?? throw new InvalidOperationException("Discovery benchmark fixture could not be deserialized.");

var baselineBytes = await File.ReadAllBytesAsync(baselinePath);
var baseline = JsonSerializer.Deserialize<BaselineReport>(
    baselineBytes,
    new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
    ?? throw new InvalidOperationException("Discovery baseline artifact could not be deserialized.");
if (!string.Equals(baseline.FixtureSha256, fixtureSha256, StringComparison.OrdinalIgnoreCase))
{
    throw new InvalidOperationException("Discovery baseline fixture SHA does not match the metamorphic source fixture.");
}

var sourceById = fixture.Queries.ToDictionary(x => x.Id, StringComparer.Ordinal);
var baselineById = baseline.QueryResults.ToDictionary(x => x.Id, StringComparer.Ordinal);
var exclusions = new List<ExcludedCase>();
var rawGenerated = new List<GeneratedCase>();

foreach (var source in fixture.Queries.OrderBy(x => x.Id, StringComparer.Ordinal))
{
    if (!baselineById.TryGetValue(source.Id, out var observed) || !SourceOraclePasses(observed))
    {
        exclusions.Add(new ExcludedCase(source.Id, "SOURCE", source.Term, null, "source-baseline-not-green"));
        continue;
    }

    foreach (var transformation in new[] { "DELETE_INTERIOR", "TRANSPOSE_INTERIOR", "DUPLICATE_INTERIOR" })
    {
        var mutation = Mutate(source.Term, transformation);
        if (!mutation.Success)
        {
            exclusions.Add(new ExcludedCase(source.Id, transformation, source.Term, null, mutation.Reason!));
            continue;
        }
        rawGenerated.Add(new GeneratedCase(
            Id: $"{source.Id}::{transformation.ToLowerInvariant()}",
            SourceQueryId: source.Id,
            SourceFamily: source.Family,
            Transformation: transformation,
            SourceTerm: source.Term,
            Term: mutation.Term!,
            NormalizedTerm: NormalizePresentation(mutation.Term!),
            Targets: source.Targets));
    }
}

var duplicateGeneratedTerms = rawGenerated
    .GroupBy(x => x.NormalizedTerm, StringComparer.Ordinal)
    .Where(x => x.Count() > 1)
    .Select(x => x.Key)
    .ToHashSet(StringComparer.Ordinal);

var normalizedSourceQueries = fixture.Queries
    .Select(x => new { Query = x, Normalized = NormalizePresentation(x.Term) })
    .ToArray();

var included = new List<GeneratedCase>();
foreach (var candidate in rawGenerated.OrderBy(x => x.Id, StringComparer.Ordinal))
{
    if (candidate.Targets.Length == 0)
    {
        exclusions.Add(ToExclusion(candidate, "empty-inherited-target-set"));
        continue;
    }
    if (string.Equals(candidate.SourceTerm, candidate.Term, StringComparison.Ordinal))
    {
        exclusions.Add(ToExclusion(candidate, "mutation-did-not-change-source"));
        continue;
    }
    if (duplicateGeneratedTerms.Contains(candidate.NormalizedTerm))
    {
        exclusions.Add(ToExclusion(candidate, "duplicate-generated-normalized-term"));
        continue;
    }

    var sourceCollision = normalizedSourceQueries.FirstOrDefault(x =>
        string.Equals(x.Normalized, candidate.NormalizedTerm, StringComparison.Ordinal) &&
        !TargetSetsEqual(x.Query.Targets, candidate.Targets));
    if (sourceCollision is not null)
    {
        exclusions.Add(ToExclusion(candidate, $"collides-with-source-query:{sourceCollision.Query.Id}"));
        continue;
    }

    var nonTargetFieldCollision = fixture.Vehicles
        .Where(x => !candidate.Targets.Contains(x.Key, StringComparer.Ordinal))
        .SelectMany(x => VehicleFields(x).Select(field => new { x.Key, Field = field }))
        .FirstOrDefault(x => string.Equals(NormalizePresentation(x.Field), candidate.NormalizedTerm, StringComparison.Ordinal));
    if (nonTargetFieldCollision is not null)
    {
        exclusions.Add(ToExclusion(candidate, $"collides-with-nontarget-field:{nonTargetFieldCollision.Key}"));
        continue;
    }

    included.Add(candidate);
}

if (included.Count == 0)
{
    throw new InvalidOperationException("Metamorphic generator produced no valid cases.");
}

var keyById = fixture.Vehicles.ToDictionary(x => Guid.Parse(x.Id), x => x.Key);
var npgsqlAssembly = Assembly.Load("Npgsql");
var connectionType = npgsqlAssembly.GetType("Npgsql.NpgsqlConnection")
    ?? throw new InvalidOperationException("NpgsqlConnection type was not found.");
var connection = Activator.CreateInstance(connectionType, connectionString) as DbConnection
    ?? throw new InvalidOperationException("NpgsqlConnection could not be created.");

await using (connection)
{
    await connection.OpenAsync();
    await ExecuteNonQueryAsync(connection, "CREATE EXTENSION IF NOT EXISTS pg_trgm;");
    await ExecuteNonQueryAsync(connection, "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;");
    var extensions = await ReadExtensionVersionsAsync(connection);

    var results = new List<QueryResult>();
    foreach (var query in included.OrderBy(x => x.Id, StringComparer.Ordinal))
    {
        CandidateScore[] candidates = Array.Empty<CandidateScore>();
        var latencies = new double[7];
        for (var index = 0; index < latencies.Length; index++)
        {
            var stopwatch = Stopwatch.StartNew();
            candidates = await LoadCandidateScoresAsync(connection, query.NormalizedTerm, keyById);
            stopwatch.Stop();
            latencies[index] = stopwatch.Elapsed.TotalMilliseconds;
        }

        if (candidates.Length != fixture.Vehicles.Length)
        {
            throw new InvalidOperationException($"Expected {fixture.Vehicles.Length} candidates for {query.Id}, got {candidates.Length}.");
        }

        var targets = query.Targets.ToHashSet(StringComparer.Ordinal);
        var methods = new[]
        {
            Evaluate("similarity", candidates, targets, x => x.Similarity, higherIsBetter: true),
            Evaluate("word_similarity", candidates, targets, x => x.WordSimilarity, higherIsBetter: true),
            Evaluate("strict_word_similarity", candidates, targets, x => x.StrictWordSimilarity, higherIsBetter: true),
            Evaluate("levenshtein", candidates, targets, x => x.LevenshteinDistance, higherIsBetter: false)
        };

        results.Add(new QueryResult(
            query.Id,
            query.SourceQueryId,
            query.SourceFamily,
            query.Transformation,
            query.SourceTerm,
            query.Term,
            query.NormalizedTerm,
            query.Targets,
            Latency(latencies),
            candidates.OrderBy(x => x.VehicleId).ToArray(),
            methods));
    }

    var transformationAggregates = results
        .SelectMany(query => query.Methods.Select(method => new { query.Transformation, Method = method }))
        .GroupBy(x => new { x.Transformation, x.Method.Method })
        .OrderBy(x => x.Key.Transformation, StringComparer.Ordinal)
        .ThenBy(x => x.Key.Method, StringComparer.Ordinal)
        .Select(group => new TransformationAggregate(
            group.Key.Transformation,
            group.Key.Method,
            group.Count(),
            group.Average(x => x.Method.Mrr),
            group.Average(x => x.Method.RecallAtTargetCount),
            group.Sum(x => x.Method.NonTargetAheadOfFirstTarget),
            group.Min(x => x.Method.TargetSeparationMargin)))
        .ToArray();

    var methodAggregates = results
        .SelectMany(query => query.Methods)
        .GroupBy(x => x.Method, StringComparer.Ordinal)
        .OrderBy(x => x.Key, StringComparer.Ordinal)
        .Select(group => new MethodAggregate(
            group.Key,
            group.Count(),
            group.Average(x => x.Mrr),
            group.Average(x => x.RecallAtTargetCount),
            group.Sum(x => x.NonTargetAheadOfFirstTarget),
            group.Min(x => x.TargetSeparationMargin)))
        .ToArray();

    var dominance = BuildDominance(results);
    var report = new MetamorphicReport(
        Schema: "bpt2.discovery-metamorphic-typo.v1",
        CodeSha: Environment.GetEnvironmentVariable("GITHUB_SHA") ?? "local",
        FixtureSchema: fixture.Schema,
        FixtureDatasetVersion: fixture.DatasetVersion,
        FixtureSha256: fixtureSha256,
        BaselineCodeSha: baseline.CodeSha,
        PostgreSqlImage: Environment.GetEnvironmentVariable("BPT_BENCHMARK_POSTGRES_IMAGE") ?? "unknown",
        Extensions: extensions,
        RecordedAtUtc: DateTime.UtcNow,
        RawGeneratedCount: rawGenerated.Count,
        IncludedCount: included.Count,
        Exclusions: exclusions.OrderBy(x => x.SourceQueryId, StringComparer.Ordinal).ThenBy(x => x.Transformation, StringComparer.Ordinal).ToArray(),
        QueryResults: results,
        TransformationAggregates: transformationAggregates,
        MethodAggregates: methodAggregates,
        Dominance: dominance,
        Notes: new[]
        {
            "Benchmark-only metamorphic characterization; no production fuzzy-search behavior is enabled.",
            "Only source queries whose executed Catalog and Public baseline have MRR=1, Recall=1 and FP=0 are eligible.",
            "Transformations and exclusion rules were frozen in issue #154 before scorer execution.",
            "Raw separation-margin magnitudes are diagnostic within a method and are not compared across Levenshtein/trigram score scales.",
            "Dominance uses per-case MRR, Recall@target-count and non-targets-ahead only; latency and raw score margins do not choose a winner."
        });

    var outputPath = Environment.GetEnvironmentVariable("BPT_METAMORPHIC_TYPO_OUTPUT")
        ?? Path.Combine("artifacts", "discovery-metamorphic-typo.json");
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outputPath))!);
    var json = JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true });
    await File.WriteAllTextAsync(outputPath, json + Environment.NewLine, Encoding.UTF8);

    Console.WriteLine($"METAMORPHIC_TYPO_FIXTURE_SHA256: {fixtureSha256}");
    Console.WriteLine($"METAMORPHIC_TYPO_CASES: raw={rawGenerated.Count} included={included.Count} excluded={exclusions.Count}");
    foreach (var aggregate in methodAggregates)
    {
        Console.WriteLine(
            $"METAMORPHIC_TYPO_METHOD_{aggregate.Method.ToUpperInvariant()}: " +
            $"queries={aggregate.QueryCount} mrr={aggregate.AverageMrr:F4} recall_at_target_count={aggregate.AverageRecallAtTargetCount:F4} " +
            $"non_target_ahead={aggregate.TotalNonTargetAheadOfFirstTarget} min_margin={aggregate.MinimumTargetSeparationMargin:F4}");
    }
    foreach (var item in dominance.Where(x => x.Dominates))
    {
        Console.WriteLine($"METAMORPHIC_TYPO_DOMINANCE: {item.BetterMethod} dominates {item.WorseMethod}");
    }
    Console.WriteLine($"METAMORPHIC_TYPO_ARTIFACT: {outputPath}");
}

static bool SourceOraclePasses(BaselineQueryResult query) =>
    NearlyOne(query.CatalogMetrics.Mrr) &&
    NearlyOne(query.CatalogMetrics.Recall) &&
    query.CatalogMetrics.FalsePositiveCount == 0 &&
    NearlyOne(query.PublicMetrics.Mrr) &&
    NearlyOne(query.PublicMetrics.Recall) &&
    query.PublicMetrics.FalsePositiveCount == 0;

static bool NearlyOne(double value) => Math.Abs(value - 1d) < 0.0000001d;

static MutationResult Mutate(string source, string transformation)
{
    var matches = Regex.Matches(source, @"[\p{L}\p{N}]+", RegexOptions.CultureInvariant)
        .Cast<Match>()
        .OrderByDescending(x => x.Length)
        .ThenBy(x => x.Index)
        .ToArray();
    var token = matches.FirstOrDefault();
    if (token is null || token.Length < 4)
    {
        return new MutationResult(false, null, "longest-token-shorter-than-4");
    }

    var middle = token.Length / 2;
    var absolute = token.Index + middle;
    return transformation switch
    {
        "DELETE_INTERIOR" => new MutationResult(true, source.Remove(absolute, 1), null),
        "DUPLICATE_INTERIOR" => new MutationResult(true, source.Insert(absolute + 1, source[absolute].ToString()), null),
        "TRANSPOSE_INTERIOR" => Transpose(source, token.Index + middle - 1, absolute),
        _ => throw new InvalidOperationException($"Unknown transformation {transformation}.")
    };
}

static MutationResult Transpose(string source, int left, int right)
{
    if (source[left] == source[right])
    {
        return new MutationResult(false, null, "transpose-characters-identical");
    }
    var chars = source.ToCharArray();
    (chars[left], chars[right]) = (chars[right], chars[left]);
    return new MutationResult(true, new string(chars), null);
}

static string NormalizePresentation(string value) =>
    value.Trim().ToLowerInvariant().Replace('-', ' ');

static bool TargetSetsEqual(IReadOnlyCollection<string> left, IReadOnlyCollection<string> right) =>
    left.Count == right.Count && left.ToHashSet(StringComparer.Ordinal).SetEquals(right);

static IEnumerable<string> VehicleFields(VehicleFixture vehicle)
{
    yield return vehicle.Brand;
    yield return vehicle.Model;
    if (!string.IsNullOrWhiteSpace(vehicle.Generation)) yield return vehicle.Generation;
    yield return vehicle.Version;
}

static ExcludedCase ToExclusion(GeneratedCase candidate, string reason) =>
    new(candidate.SourceQueryId, candidate.Transformation, candidate.SourceTerm, candidate.Term, reason);

static async Task ExecuteNonQueryAsync(DbConnection connection, string sql)
{
    await using var command = connection.CreateCommand();
    command.CommandText = sql;
    await command.ExecuteNonQueryAsync();
}

static async Task<string[]> ReadExtensionVersionsAsync(DbConnection connection)
{
    await using var command = connection.CreateCommand();
    command.CommandText = """
        SELECT extname || ':' || extversion
        FROM pg_extension
        WHERE extname IN ('pg_trgm', 'fuzzystrmatch')
        ORDER BY extname;
        """;
    var values = new List<string>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync()) values.Add(reader.GetString(0));
    if (values.Count != 2)
    {
        throw new InvalidOperationException("Expected pg_trgm and fuzzystrmatch extensions to be available.");
    }
    return values.ToArray();
}

static async Task<CandidateScore[]> LoadCandidateScoresAsync(
    DbConnection connection,
    string normalizedQuery,
    IReadOnlyDictionary<Guid, string> keyById)
{
    await using var command = connection.CreateCommand();
    command.CommandText = """
        SELECT
            v."Id",
            GREATEST(
                similarity(@query, lower(replace(btrim(b."Name"), '-', ' '))),
                similarity(@query, lower(replace(btrim(m."Name"), '-', ' '))),
                similarity(@query, lower(replace(btrim(ver."Name"), '-', ' '))),
                COALESCE(similarity(@query, lower(replace(btrim(g."Name"), '-', ' '))), 0)
            ) AS similarity_score,
            GREATEST(
                word_similarity(@query, lower(replace(btrim(b."Name"), '-', ' '))),
                word_similarity(@query, lower(replace(btrim(m."Name"), '-', ' '))),
                word_similarity(@query, lower(replace(btrim(ver."Name"), '-', ' '))),
                COALESCE(word_similarity(@query, lower(replace(btrim(g."Name"), '-', ' '))), 0)
            ) AS word_similarity_score,
            GREATEST(
                strict_word_similarity(@query, lower(replace(btrim(b."Name"), '-', ' '))),
                strict_word_similarity(@query, lower(replace(btrim(m."Name"), '-', ' '))),
                strict_word_similarity(@query, lower(replace(btrim(ver."Name"), '-', ' '))),
                COALESCE(strict_word_similarity(@query, lower(replace(btrim(g."Name"), '-', ' '))), 0)
            ) AS strict_word_similarity_score,
            LEAST(
                levenshtein(@query, lower(replace(btrim(b."Name"), '-', ' '))),
                levenshtein(@query, lower(replace(btrim(m."Name"), '-', ' '))),
                levenshtein(@query, lower(replace(btrim(ver."Name"), '-', ' '))),
                CASE WHEN g."Name" IS NULL THEN 2147483647
                     ELSE levenshtein(@query, lower(replace(btrim(g."Name"), '-', ' '))) END
            ) AS levenshtein_distance
        FROM "CatalogVehicles" AS v
        INNER JOIN "CatalogBrands" AS b ON v."BrandId" = b."Id"
        INNER JOIN "CatalogModels" AS m ON v."ModelId" = m."Id"
        INNER JOIN "CatalogVersions" AS ver ON v."VersionId" = ver."Id"
        LEFT JOIN "CatalogGenerations" AS g ON v."GenerationId" = g."Id"
        ORDER BY v."Id";
        """;
    var parameter = command.CreateParameter();
    parameter.ParameterName = "query";
    parameter.Value = normalizedQuery;
    command.Parameters.Add(parameter);

    var rows = new List<CandidateScore>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        var vehicleId = reader.GetGuid(0);
        if (!keyById.TryGetValue(vehicleId, out var key))
        {
            throw new InvalidOperationException($"Unexpected VehicleId in metamorphic benchmark: {vehicleId}");
        }
        rows.Add(new CandidateScore(
            vehicleId,
            key,
            Convert.ToDouble(reader.GetValue(1)),
            Convert.ToDouble(reader.GetValue(2)),
            Convert.ToDouble(reader.GetValue(3)),
            reader.GetInt32(4)));
    }
    return rows.ToArray();
}

static MethodEvaluation Evaluate(
    string method,
    IReadOnlyList<CandidateScore> candidates,
    HashSet<string> targets,
    Func<CandidateScore, double> score,
    bool higherIsBetter)
{
    var ranked = higherIsBetter
        ? candidates.OrderByDescending(score).ThenBy(x => x.VehicleId).ToArray()
        : candidates.OrderBy(score).ThenBy(x => x.VehicleId).ToArray();

    var firstRelevantIndex = Array.FindIndex(ranked, x => targets.Contains(x.Key));
    var mrr = firstRelevantIndex < 0 ? 0d : 1d / (firstRelevantIndex + 1);
    var k = targets.Count;
    var recallAtK = k == 0 ? 1d : (double)ranked.Take(k).Count(x => targets.Contains(x.Key)) / k;
    var nonTargetAhead = firstRelevantIndex < 0 ? ranked.Length : firstRelevantIndex;

    var targetScores = ranked.Where(x => targets.Contains(x.Key)).Select(score).ToArray();
    var nonTargetScores = ranked.Where(x => !targets.Contains(x.Key)).Select(score).ToArray();
    if (targetScores.Length == 0 || nonTargetScores.Length == 0)
    {
        throw new InvalidOperationException($"Method {method} cannot calculate target separation.");
    }
    var margin = higherIsBetter
        ? targetScores.Max() - nonTargetScores.Max()
        : nonTargetScores.Min() - targetScores.Min();

    return new MethodEvaluation(
        method,
        mrr,
        recallAtK,
        nonTargetAhead,
        margin,
        ranked.Select((x, index) => new RankedCandidate(index + 1, x.VehicleId, x.Key, score(x))).ToArray());
}

static DominanceResult[] BuildDominance(IReadOnlyList<QueryResult> results)
{
    var methods = results.SelectMany(x => x.Methods).Select(x => x.Method).Distinct(StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal).ToArray();
    var output = new List<DominanceResult>();
    foreach (var worse in methods)
    {
        foreach (var better in methods.Where(x => !string.Equals(x, worse, StringComparison.Ordinal)))
        {
            var noWorseEverywhere = true;
            var strictlyBetterSomewhere = false;
            foreach (var query in results)
            {
                var a = query.Methods.Single(x => string.Equals(x.Method, worse, StringComparison.Ordinal));
                var b = query.Methods.Single(x => string.Equals(x.Method, better, StringComparison.Ordinal));
                var noWorse = b.Mrr >= a.Mrr && b.RecallAtTargetCount >= a.RecallAtTargetCount && b.NonTargetAheadOfFirstTarget <= a.NonTargetAheadOfFirstTarget;
                if (!noWorse)
                {
                    noWorseEverywhere = false;
                    break;
                }
                if (b.Mrr > a.Mrr || b.RecallAtTargetCount > a.RecallAtTargetCount || b.NonTargetAheadOfFirstTarget < a.NonTargetAheadOfFirstTarget)
                {
                    strictlyBetterSomewhere = true;
                }
            }
            output.Add(new DominanceResult(better, worse, noWorseEverywhere && strictlyBetterSomewhere));
        }
    }
    return output.OrderBy(x => x.BetterMethod, StringComparer.Ordinal).ThenBy(x => x.WorseMethod, StringComparer.Ordinal).ToArray();
}

static LatencySummary Latency(double[] values)
{
    var ordered = values.OrderBy(x => x).ToArray();
    return new LatencySummary(ordered[0], Percentile(ordered, 0.50), Percentile(ordered, 0.95), ordered[^1]);
}

static double Percentile(double[] ordered, double percentile)
{
    if (ordered.Length == 1) return ordered[0];
    var position = (ordered.Length - 1) * percentile;
    var lower = (int)Math.Floor(position);
    var upper = (int)Math.Ceiling(position);
    if (lower == upper) return ordered[lower];
    var fraction = position - lower;
    return ordered[lower] + ((ordered[upper] - ordered[lower]) * fraction);
}

public sealed record DiscoveryFixture(string Schema, string DatasetVersion, VehicleFixture[] Vehicles, QueryFixture[] Queries);
public sealed record VehicleFixture(string Key, string Id, string Brand, string Model, string? Generation, string Version, int? ModelYear);
public sealed record QueryFixture(string Id, string Family, string Term, string[] Targets);
public sealed record BaselineReport(string Schema, string CodeSha, string FixtureSha256, BaselineQueryResult[] QueryResults);
public sealed record BaselineQueryResult(string Id, BaselineMetrics CatalogMetrics, BaselineMetrics PublicMetrics);
public sealed record BaselineMetrics(double Mrr, double Recall, int FalsePositiveCount, int ResultCount);
public sealed record MutationResult(bool Success, string? Term, string? Reason);
public sealed record GeneratedCase(string Id, string SourceQueryId, string SourceFamily, string Transformation, string SourceTerm, string Term, string NormalizedTerm, string[] Targets);
public sealed record ExcludedCase(string SourceQueryId, string Transformation, string SourceTerm, string? GeneratedTerm, string Reason);
public sealed record CandidateScore(Guid VehicleId, string Key, double Similarity, double WordSimilarity, double StrictWordSimilarity, int LevenshteinDistance);
public sealed record RankedCandidate(int Rank, Guid VehicleId, string Key, double Score);
public sealed record MethodEvaluation(string Method, double Mrr, double RecallAtTargetCount, int NonTargetAheadOfFirstTarget, double TargetSeparationMargin, IReadOnlyList<RankedCandidate> RankedCandidates);
public sealed record LatencySummary(double MinMs, double P50Ms, double P95Ms, double MaxMs);
public sealed record QueryResult(string Id, string SourceQueryId, string SourceFamily, string Transformation, string SourceTerm, string Term, string NormalizedTerm, string[] Targets, LatencySummary ScoreQueryLatency, IReadOnlyList<CandidateScore> CandidateScores, IReadOnlyList<MethodEvaluation> Methods);
public sealed record TransformationAggregate(string Transformation, string Method, int QueryCount, double AverageMrr, double AverageRecallAtTargetCount, int TotalNonTargetAheadOfFirstTarget, double MinimumTargetSeparationMargin);
public sealed record MethodAggregate(string Method, int QueryCount, double AverageMrr, double AverageRecallAtTargetCount, int TotalNonTargetAheadOfFirstTarget, double MinimumTargetSeparationMargin);
public sealed record DominanceResult(string BetterMethod, string WorseMethod, bool Dominates);
public sealed record MetamorphicReport(string Schema, string CodeSha, string FixtureSchema, string FixtureDatasetVersion, string FixtureSha256, string BaselineCodeSha, string PostgreSqlImage, IReadOnlyList<string> Extensions, DateTime RecordedAtUtc, int RawGeneratedCount, int IncludedCount, IReadOnlyList<ExcludedCase> Exclusions, IReadOnlyList<QueryResult> QueryResults, IReadOnlyList<TransformationAggregate> TransformationAggregates, IReadOnlyList<MethodAggregate> MethodAggregates, IReadOnlyList<DominanceResult> Dominance, IReadOnlyList<string> Notes);
