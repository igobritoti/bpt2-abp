using System.Data.Common;
using System.Diagnostics;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
}

var fixturePath = Path.Combine(AppContext.BaseDirectory, "benchmarks", "discovery_br_v1.json");
var fixtureBytes = await File.ReadAllBytesAsync(fixturePath);
var fixtureSha256 = Convert.ToHexString(SHA256.HashData(fixtureBytes)).ToLowerInvariant();
var fixture = JsonSerializer.Deserialize<DiscoveryFixture>(
    fixtureBytes,
    new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
    ?? throw new InvalidOperationException("Discovery benchmark fixture could not be deserialized.");

var typoQueries = fixture.Queries
    .Where(x => string.Equals(x.Family, "typo", StringComparison.Ordinal))
    .ToArray();
if (typoQueries.Length == 0)
{
    throw new InvalidOperationException("Frozen discovery fixture contains no typo queries.");
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

    var queryResults = new List<QueryScoringResult>();
    foreach (var query in typoQueries)
    {
        var normalizedQuery = NormalizePresentation(query.Term);
        CandidateScore[] candidates = Array.Empty<CandidateScore>();
        var latencies = new double[7];
        for (var index = 0; index < latencies.Length; index++)
        {
            var stopwatch = Stopwatch.StartNew();
            candidates = await LoadCandidateScoresAsync(connection, normalizedQuery, keyById);
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

        queryResults.Add(new QueryScoringResult(
            query.Id,
            query.Term,
            normalizedQuery,
            query.Targets,
            Latency(latencies),
            candidates.OrderBy(x => x.VehicleId).ToArray(),
            methods));
    }

    var methodAggregates = queryResults
        .SelectMany(x => x.Methods)
        .GroupBy(x => x.Method, StringComparer.Ordinal)
        .OrderBy(x => x.Key, StringComparer.Ordinal)
        .Select(group => new MethodAggregate(
            group.Key,
            group.Average(x => x.Mrr),
            group.Average(x => x.RecallAtTargetCount),
            group.Sum(x => x.NonTargetAheadOfFirstTarget),
            group.Min(x => x.TargetSeparationMargin)))
        .ToArray();

    var representativePlan = await CaptureRepresentativePlanAsync(connection, NormalizePresentation(typoQueries[0].Term));
    var report = new TypoScoringReport(
        Schema: "bpt2.discovery-typo-scoring.v1",
        CodeSha: Environment.GetEnvironmentVariable("GITHUB_SHA") ?? "local",
        FixtureSchema: fixture.Schema,
        FixtureDatasetVersion: fixture.DatasetVersion,
        FixtureSha256: fixtureSha256,
        PostgreSqlImage: Environment.GetEnvironmentVariable("BPT_BENCHMARK_POSTGRES_IMAGE") ?? "unknown",
        Extensions: extensions,
        RecordedAtUtc: DateTime.UtcNow,
        QueryResults: queryResults,
        MethodAggregates: methodAggregates,
        RepresentativeExplainAnalyze: representativePlan,
        Notes: new[]
        {
            "Benchmark-only characterization; no production fuzzy-search behavior is enabled.",
            "Query/field normalization is trim + lowercase + ASCII hyphen-to-space only, matching the presentation experiment boundary.",
            "Each method scores Brand, Model, optional Generation and Version independently; trigram score uses the maximum field score and Levenshtein uses the minimum field distance.",
            "Recall@K uses K equal to the frozen qrel target count for evaluation only; K is not a production search policy.",
            "PostgreSQL extension default thresholds are not used as BPT2 acceptance thresholds."
        });

    var outputPath = Environment.GetEnvironmentVariable("BPT_TYPO_SCORING_OUTPUT")
        ?? Path.Combine("artifacts", "discovery-typo-scoring.json");
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outputPath))!);
    var json = JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true });
    await File.WriteAllTextAsync(outputPath, json + Environment.NewLine, Encoding.UTF8);

    Console.WriteLine($"TYPO_SCORING_FIXTURE_SHA256: {fixtureSha256}");
    Console.WriteLine($"TYPO_SCORING_EXTENSIONS: {string.Join(",", extensions)}");
    foreach (var aggregate in methodAggregates)
    {
        Console.WriteLine(
            $"TYPO_SCORING_METHOD_{aggregate.Method.ToUpperInvariant()}: " +
            $"mrr={aggregate.AverageMrr:F4} recall_at_target_count={aggregate.AverageRecallAtTargetCount:F4} " +
            $"non_target_ahead={aggregate.TotalNonTargetAheadOfFirstTarget} min_margin={aggregate.MinimumTargetSeparationMargin:F4}");
    }
    Console.WriteLine($"TYPO_SCORING_ARTIFACT: {outputPath}");
}

static string NormalizePresentation(string value) =>
    value.Trim().ToLowerInvariant().Replace('-', ' ');

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
    while (await reader.ReadAsync())
    {
        values.Add(reader.GetString(0));
    }
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
            b."Name",
            m."Name",
            g."Name",
            ver."Name",
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
            throw new InvalidOperationException($"Unexpected VehicleId in typo benchmark: {vehicleId}");
        }
        rows.Add(new CandidateScore(
            vehicleId,
            key,
            reader.GetString(1),
            reader.GetString(2),
            reader.IsDBNull(3) ? null : reader.GetString(3),
            reader.GetString(4),
            Convert.ToDouble(reader.GetValue(5)),
            Convert.ToDouble(reader.GetValue(6)),
            Convert.ToDouble(reader.GetValue(7)),
            reader.GetInt32(8)));
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
    var recallAtK = k == 0
        ? 1d
        : (double)ranked.Take(k).Count(x => targets.Contains(x.Key)) / k;
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

static async Task<string[]> CaptureRepresentativePlanAsync(DbConnection connection, string normalizedQuery)
{
    await using var command = connection.CreateCommand();
    command.CommandText = """
        EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
        SELECT v."Id"
        FROM "CatalogVehicles" AS v
        INNER JOIN "CatalogBrands" AS b ON v."BrandId" = b."Id"
        INNER JOIN "CatalogModels" AS m ON v."ModelId" = m."Id"
        INNER JOIN "CatalogVersions" AS ver ON v."VersionId" = ver."Id"
        LEFT JOIN "CatalogGenerations" AS g ON v."GenerationId" = g."Id"
        ORDER BY GREATEST(
            word_similarity(@query, lower(replace(btrim(b."Name"), '-', ' '))),
            word_similarity(@query, lower(replace(btrim(m."Name"), '-', ' '))),
            word_similarity(@query, lower(replace(btrim(ver."Name"), '-', ' '))),
            COALESCE(word_similarity(@query, lower(replace(btrim(g."Name"), '-', ' '))), 0)
        ) DESC, v."Id";
        """;
    var parameter = command.CreateParameter();
    parameter.ParameterName = "query";
    parameter.Value = normalizedQuery;
    command.Parameters.Add(parameter);

    var lines = new List<string>();
    await using var reader = await command.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        lines.Add(reader.GetString(0));
    }
    return lines.ToArray();
}

public sealed record DiscoveryFixture(string Schema, string DatasetVersion, VehicleFixture[] Vehicles, QueryFixture[] Queries);
public sealed record VehicleFixture(string Key, string Id, string Brand, string Model, string? Generation, string Version, int? ModelYear);
public sealed record QueryFixture(string Id, string Family, string Term, string[] Targets);
public sealed record CandidateScore(
    Guid VehicleId,
    string Key,
    string Brand,
    string Model,
    string? Generation,
    string Version,
    double Similarity,
    double WordSimilarity,
    double StrictWordSimilarity,
    int LevenshteinDistance);
public sealed record RankedCandidate(int Rank, Guid VehicleId, string Key, double Score);
public sealed record MethodEvaluation(
    string Method,
    double Mrr,
    double RecallAtTargetCount,
    int NonTargetAheadOfFirstTarget,
    double TargetSeparationMargin,
    IReadOnlyList<RankedCandidate> RankedCandidates);
public sealed record LatencySummary(double MinMs, double P50Ms, double P95Ms, double MaxMs);
public sealed record QueryScoringResult(
    string Id,
    string Term,
    string NormalizedTerm,
    string[] Targets,
    LatencySummary ScoreQueryLatency,
    IReadOnlyList<CandidateScore> CandidateScores,
    IReadOnlyList<MethodEvaluation> Methods);
public sealed record MethodAggregate(
    string Method,
    double AverageMrr,
    double AverageRecallAtTargetCount,
    int TotalNonTargetAheadOfFirstTarget,
    double MinimumTargetSeparationMargin);
public sealed record TypoScoringReport(
    string Schema,
    string CodeSha,
    string FixtureSchema,
    string FixtureDatasetVersion,
    string FixtureSha256,
    string PostgreSqlImage,
    IReadOnlyList<string> Extensions,
    DateTime RecordedAtUtc,
    IReadOnlyList<QueryScoringResult> QueryResults,
    IReadOnlyList<MethodAggregate> MethodAggregates,
    IReadOnlyList<string> RepresentativeExplainAnalyze,
    IReadOnlyList<string> Notes);
