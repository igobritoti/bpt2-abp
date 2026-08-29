using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BomPraTi.Catalog;
using BomPraTi.Catalog.Contracts;
using BomPraTi.Catalog.Data;
using BomPraTi.Catalog.Domain;
using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using BomPraTi.Sellers.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp;
using Volo.Abp.Autofac;
using Volo.Abp.Data;
using Volo.Abp.Modularity;
using Volo.Abp.Uow;

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

DiscoveryBenchmarkModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<DiscoveryBenchmarkModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    await SeedAsync(application.ServiceProvider, fixture);

    BenchmarkReport report = null!;
    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        var catalog = services.GetRequiredService<IVehicleCatalogReader>();
        var publicListings = services.GetRequiredService<IPublicListingQuery>();
        var catalogDb = services.GetRequiredService<CatalogDbContext>();
        var keyById = fixture.Vehicles.ToDictionary(x => Guid.Parse(x.Id), x => x.Key);
        var queryResults = new List<QueryBenchmarkResult>();

        foreach (var query in fixture.Queries)
        {
            var targetKeys = query.Targets.ToHashSet(StringComparer.Ordinal);
            IReadOnlyList<VehicleRefDto> catalogItems = Array.Empty<VehicleRefDto>();
            var catalogLatencies = await MeasureAsync(async () =>
            {
                catalogItems = await catalog.SearchAsync(new VehicleCatalogSearchInput(Query: query.Term), take: 100);
            });

            IReadOnlyList<PublicListingDto> publicItems = Array.Empty<PublicListingDto>();
            var publicLatencies = await MeasureAsync(async () =>
            {
                publicItems = await publicListings.SearchAsync(new PublicListingSearchInput
                {
                    Query = query.Term,
                    Skip = 0,
                    Take = 100
                });
            });

            var catalogKeys = catalogItems.Select(x => keyById.GetValueOrDefault(x.Id)).Where(x => x is not null).Cast<string>().ToArray();
            var publicKeys = publicItems.Select(x => keyById.GetValueOrDefault(x.VehicleId)).Where(x => x is not null).Cast<string>().ToArray();

            queryResults.Add(new QueryBenchmarkResult(
                query.Id,
                query.Family,
                query.Term,
                query.Targets,
                Metrics(targetKeys, catalogKeys),
                Metrics(targetKeys, publicKeys),
                Latency(catalogLatencies),
                Latency(publicLatencies),
                catalogKeys,
                publicKeys));
        }

        var facetResults = new List<FacetBenchmarkResult>();
        foreach (var facetCase in fixture.FacetCases)
        {
            var page = await publicListings.SearchPageAsync(ToSearchInput(facetCase.Input));
            var actual = checked((int)page.TotalCount);
            facetResults.Add(new FacetBenchmarkResult(facetCase.Id, facetCase.ExpectedCount, actual, actual == facetCase.ExpectedCount));
        }

        if (facetResults.Any(x => !x.ExactMatch))
        {
            var failed = string.Join(", ", facetResults.Where(x => !x.ExactMatch).Select(x => x.Id));
            throw new InvalidOperationException("Facet oracle mismatch: " + failed);
        }

        var plan = await CaptureRepresentativePlanAsync(catalogDb);
        var familyAggregates = queryResults
            .GroupBy(x => x.Family, StringComparer.Ordinal)
            .OrderBy(x => x.Key, StringComparer.Ordinal)
            .Select(group => new FamilyAggregate(
                group.Key,
                group.Count(),
                group.Average(x => x.CatalogMetrics.Mrr),
                group.Average(x => x.CatalogMetrics.Recall),
                group.Sum(x => x.CatalogMetrics.FalsePositiveCount),
                group.Average(x => x.PublicMetrics.Mrr),
                group.Average(x => x.PublicMetrics.Recall),
                group.Sum(x => x.PublicMetrics.FalsePositiveCount)))
            .ToArray();

        report = new BenchmarkReport(
            Schema: "bpt2.discovery-baseline-result.v1",
            CodeSha: Environment.GetEnvironmentVariable("GITHUB_SHA") ?? "local",
            FixtureSchema: fixture.Schema,
            FixtureDatasetVersion: fixture.DatasetVersion,
            FixtureSha256: fixtureSha256,
            PostgreSqlImage: Environment.GetEnvironmentVariable("BPT_BENCHMARK_POSTGRES_IMAGE") ?? "unknown",
            RecordedAtUtc: DateTime.UtcNow,
            QueryResults: queryResults,
            FamilyAggregates: familyAggregates,
            FacetResults: facetResults,
            RepresentativeExplainAnalyze: plan,
            Notes: new[]
            {
                "This is a baseline measurement, not a product acceptance threshold.",
                "Typo/presentation/autocomplete families expose current behavior; they do not fail the benchmark when recall is low.",
                "Facet cases are exact regression oracles and must agree with the independent fixture expectations.",
                "No technical-only distinction from Podium is used as a discovery relevance label."
            });
    });

    var outputPath = Environment.GetEnvironmentVariable("BPT_DISCOVERY_BENCHMARK_OUTPUT") ?? Path.Combine("artifacts", "discovery-baseline.json");
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outputPath))!);
    var json = JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true });
    await File.WriteAllTextAsync(outputPath, json + Environment.NewLine, Encoding.UTF8);

    Console.WriteLine($"DISCOVERY_FIXTURE_SHA256: {fixtureSha256}");
    foreach (var family in report.FamilyAggregates)
    {
        Console.WriteLine($"DISCOVERY_FAMILY_{family.Family.ToUpperInvariant()}: catalog_mrr={family.CatalogMrr:F4} catalog_recall={family.CatalogRecall:F4} public_mrr={family.PublicMrr:F4} public_recall={family.PublicRecall:F4} catalog_fp={family.CatalogFalsePositiveCount} public_fp={family.PublicFalsePositiveCount}");
    }
    Console.WriteLine($"DISCOVERY_FACET_ORACLE: PASS ({report.FacetResults.Count}/{report.FacetResults.Count})");
    Console.WriteLine($"DISCOVERY_BASELINE_ARTIFACT: {outputPath}");
}
finally
{
    await application.ShutdownAsync();
}

static async Task SeedAsync(IServiceProvider root, DiscoveryFixture fixture)
{
    await InNewUnitOfWorkAsync(root, async services =>
    {
        var catalog = services.GetRequiredService<CatalogDbContext>();
        var marketplace = services.GetRequiredService<MarketplaceDbContext>();
        var benchmarkVehicleIds = fixture.Vehicles.Select(v => Guid.Parse(v.Id)).ToArray();
        if (await catalog.Vehicles.AnyAsync(x => benchmarkVehicleIds.Contains(x.Id)))
        {
            throw new InvalidOperationException("Discovery benchmark Vehicle IDs already exist; use a fresh database.");
        }

        var vehicleIdByKey = new Dictionary<string, Guid>(StringComparer.Ordinal);
        var brandByName = new Dictionary<string, Brand>(StringComparer.OrdinalIgnoreCase);
        var modelByKey = new Dictionary<string, VehicleModel>(StringComparer.OrdinalIgnoreCase);
        var generationByKey = new Dictionary<string, Generation>(StringComparer.OrdinalIgnoreCase);
        var versionByKey = new Dictionary<string, VehicleVersion>(StringComparer.OrdinalIgnoreCase);
        var sequence = 1;

        foreach (var item in fixture.Vehicles)
        {
            if (!brandByName.TryGetValue(item.Brand, out var brand))
            {
                brand = new Brand(StableGuid(3000 + sequence++), item.Brand);
                brandByName[item.Brand] = brand;
                catalog.Brands.Add(brand);
            }

            var modelKey = $"{item.Brand}|{item.Model}";
            if (!modelByKey.TryGetValue(modelKey, out var model))
            {
                model = new VehicleModel(StableGuid(3000 + sequence++), brand.Id, item.Model);
                modelByKey[modelKey] = model;
                catalog.Models.Add(model);
            }

            Generation? generation = null;
            if (!string.IsNullOrWhiteSpace(item.Generation))
            {
                var generationKey = $"{modelKey}|{item.Generation}";
                if (!generationByKey.TryGetValue(generationKey, out generation))
                {
                    generation = new Generation(StableGuid(3000 + sequence++), model.Id, item.Generation, null, null);
                    generationByKey[generationKey] = generation;
                    catalog.Generations.Add(generation);
                }
            }

            var versionKey = $"{modelKey}|{generation?.Id}|{item.Version}";
            if (!versionByKey.TryGetValue(versionKey, out var version))
            {
                version = new VehicleVersion(StableGuid(3000 + sequence++), model.Id, generation?.Id, item.Version);
                versionByKey[versionKey] = version;
                catalog.Versions.Add(version);
            }

            var vehicleId = Guid.Parse(item.Id);
            catalog.Vehicles.Add(new Vehicle(vehicleId, brand.Id, model.Id, generation?.Id, version.Id, item.ModelYear));
            vehicleIdByKey[item.Key] = vehicleId;
        }
        await catalog.SaveChangesAsync();

        var sellerId = Guid.Parse("40000000-0000-0000-0000-000000000001");
        var publishedAt = new DateTime(2026, 8, 29, 12, 0, 0, DateTimeKind.Utc);
        foreach (var item in fixture.Listings)
        {
            var listing = new Listing(
                Guid.Parse(item.Id), sellerId, vehicleIdByKey[item.VehicleKey], item.Title, item.Price,
                "Fixture versionada do benchmark de discovery.", 2024, item.MileageKm, item.Color, item.City, item.StateCode);
            if (item.Published)
            {
                listing.Publish(publishedAt);
            }
            marketplace.Listings.Add(listing);
        }
        await marketplace.SaveChangesAsync();
    });
}

static Guid StableGuid(int suffix) => Guid.Parse($"30000000-0000-0000-0000-{suffix:000000000000}");

static async Task<double[]> MeasureAsync(Func<Task> action)
{
    const int repetitions = 7;
    var values = new double[repetitions];
    for (var index = 0; index < repetitions; index++)
    {
        var stopwatch = Stopwatch.StartNew();
        await action();
        stopwatch.Stop();
        values[index] = stopwatch.Elapsed.TotalMilliseconds;
    }
    return values;
}

static RetrievalMetrics Metrics(HashSet<string> targets, IReadOnlyList<string> results)
{
    var firstRelevant = -1;
    var found = new HashSet<string>(StringComparer.Ordinal);
    var falsePositives = 0;
    for (var index = 0; index < results.Count; index++)
    {
        var key = results[index];
        if (targets.Contains(key))
        {
            found.Add(key);
            if (firstRelevant < 0) firstRelevant = index;
        }
        else
        {
            falsePositives++;
        }
    }
    return new RetrievalMetrics(
        firstRelevant < 0 ? 0d : 1d / (firstRelevant + 1),
        targets.Count == 0 ? 1d : (double)found.Count / targets.Count,
        falsePositives,
        results.Count);
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

static PublicListingSearchInput ToSearchInput(FacetInput input) => new()
{
    Brand = input.Brand,
    Model = input.Model,
    Color = input.Color,
    City = input.City,
    StateCode = input.StateCode,
    MinModelYear = input.MinModelYear,
    MaxModelYear = input.MaxModelYear,
    MinPrice = input.MinPrice,
    MaxPrice = input.MaxPrice,
    MinMileageKm = input.MinMileageKm,
    MaxMileageKm = input.MaxMileageKm,
    Query = input.Query,
    Skip = 0,
    Take = 100
};

static async Task<string[]> CaptureRepresentativePlanAsync(CatalogDbContext db)
{
    var connection = db.Database.GetDbConnection();
    var shouldClose = connection.State == System.Data.ConnectionState.Closed;
    if (shouldClose) await connection.OpenAsync();
    try
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
            SELECT DISTINCT v."Id"
            FROM "CatalogVehicles" AS v
            INNER JOIN "CatalogBrands" AS b ON v."BrandId" = b."Id"
            INNER JOIN "CatalogModels" AS m ON v."ModelId" = m."Id"
            INNER JOIN "CatalogVersions" AS ver ON v."VersionId" = ver."Id"
            LEFT JOIN "CatalogGenerations" AS g ON v."GenerationId" = g."Id"
            WHERE lower(b."Name") LIKE '%corolla%'
               OR lower(m."Name") LIKE '%corolla%'
               OR lower(ver."Name") LIKE '%corolla%'
               OR (g."Id" IS NOT NULL AND lower(g."Name") LIKE '%corolla%')
            ORDER BY v."Id";
            """;
        var lines = new List<string>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) lines.Add(reader.GetString(0));
        return lines.ToArray();
    }
    finally
    {
        if (shouldClose) await connection.CloseAsync();
    }
}

static async Task InNewUnitOfWorkAsync(IServiceProvider root, Func<IServiceProvider, Task> action)
{
    using var scope = root.CreateScope();
    var uowManager = scope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var uow = uowManager.Begin(requiresNew: true, isTransactional: true);
    await action(scope.ServiceProvider);
    await uow.CompleteAsync();
}

[DependsOn(typeof(AbpAutofacModule), typeof(BomPraTiCatalogModule), typeof(BomPraTiMarketplaceModule))]
public sealed class DiscoveryBenchmarkModule : AbpModule
{
    public static string ConnectionString { get; set; } = null!;
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpDbConnectionOptions>(options => options.ConnectionStrings.Default = ConnectionString);
        context.Services.AddSingleton<IMediaAssetReader, EmptyMediaAssetReader>();
        context.Services.AddSingleton<ISellerPublicReader, BenchmarkSellerPublicReader>();
    }
}

public sealed class EmptyMediaAssetReader : IMediaAssetReader
{
    public Task<MediaAssetRefDto?> GetAsync(Guid mediaAssetId, CancellationToken cancellationToken = default) => Task.FromResult<MediaAssetRefDto?>(null);
    public Task<IReadOnlyList<MediaAssetRefDto>> GetManyAsync(IReadOnlyCollection<Guid> mediaAssetIds, CancellationToken cancellationToken = default) => Task.FromResult<IReadOnlyList<MediaAssetRefDto>>(Array.Empty<MediaAssetRefDto>());
}

public sealed class BenchmarkSellerPublicReader : ISellerPublicReader
{
    public Task<SellerPublicContactDto?> GetAsync(Guid sellerId, CancellationToken cancellationToken = default) => Task.FromResult<SellerPublicContactDto?>(new SellerPublicContactDto(sellerId, "Benchmark Seller", "+5511999999999"));
    public Task<IReadOnlyList<SellerPublicContactDto>> GetManyAsync(IReadOnlyCollection<Guid> sellerIds, CancellationToken cancellationToken = default) => Task.FromResult<IReadOnlyList<SellerPublicContactDto>>(sellerIds.Select(id => new SellerPublicContactDto(id, "Benchmark Seller", "+5511999999999")).ToArray());
}

public sealed record DiscoveryFixture(string Schema, string DatasetVersion, SourceMetadata Source, VehicleFixture[] Vehicles, ListingFixture[] Listings, QueryFixture[] Queries, FacetFixture[] FacetCases);
public sealed record SourceMetadata(string Repository, string Commit, string Path, string DatasetVersion, string[] NonClaims);
public sealed record VehicleFixture(string Key, string Id, string Brand, string Model, string? Generation, string Version, int? ModelYear);
public sealed record ListingFixture(string Id, string VehicleKey, string Title, decimal Price, int? MileageKm, string? Color, string City, string StateCode, bool Published);
public sealed record QueryFixture(string Id, string Family, string Term, string[] Targets);
public sealed record FacetFixture(string Id, FacetInput Input, int ExpectedCount);
public sealed record FacetInput(string? Brand = null, string? Model = null, string? Color = null, string? City = null, string? StateCode = null, int? MinModelYear = null, int? MaxModelYear = null, decimal? MinPrice = null, decimal? MaxPrice = null, int? MinMileageKm = null, int? MaxMileageKm = null, string? Query = null);
public sealed record RetrievalMetrics(double Mrr, double Recall, int FalsePositiveCount, int ResultCount);
public sealed record LatencySummary(double MinMs, double P50Ms, double P95Ms, double MaxMs);
public sealed record QueryBenchmarkResult(string Id, string Family, string Term, string[] Targets, RetrievalMetrics CatalogMetrics, RetrievalMetrics PublicMetrics, LatencySummary CatalogLatency, LatencySummary PublicLatency, string[] CatalogResults, string[] PublicResults);
public sealed record FacetBenchmarkResult(string Id, int ExpectedCount, int ActualCount, bool ExactMatch);
public sealed record FamilyAggregate(string Family, int QueryCount, double CatalogMrr, double CatalogRecall, int CatalogFalsePositiveCount, double PublicMrr, double PublicRecall, int PublicFalsePositiveCount);
public sealed record BenchmarkReport(string Schema, string CodeSha, string FixtureSchema, string FixtureDatasetVersion, string FixtureSha256, string PostgreSqlImage, DateTime RecordedAtUtc, IReadOnlyList<QueryBenchmarkResult> QueryResults, IReadOnlyList<FamilyAggregate> FamilyAggregates, IReadOnlyList<FacetBenchmarkResult> FacetResults, string[] RepresentativeExplainAnalyze, string[] Notes);
