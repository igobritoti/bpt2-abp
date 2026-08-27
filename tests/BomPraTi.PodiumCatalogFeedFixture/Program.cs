using System.Security.Claims;
using BomPraTi.Catalog;
using BomPraTi.Ingestion;
using BomPraTi.Ingestion.Contracts;
using BomPraTi.Ingestion.Domain;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp;
using Volo.Abp.Autofac;
using Volo.Abp.Data;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Modularity;
using Volo.Abp.Security.Claims;
using Volo.Abp.Uow;

static void Require(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
}

PodiumCatalogFeedFixtureModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<PodiumCatalogFeedFixtureModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    var suffix = Guid.NewGuid().ToString("N")[..10];
    var canonicalId = $"veh_{Guid.NewGuid():N}";
    var redirectId = $"veh_{Guid.NewGuid():N}";

    PodiumCatalogImportResultDto first = null!;
    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeAdmin(services);
        var feed = services.GetRequiredService<IPodiumCatalogFeedAppService>();
        first = await feed.ImportAsync(CreateInput(canonicalId, redirectId, suffix));
    });

    Require(!first.Replayed, "First Podium import was incorrectly marked as replay.");
    Require(first.CanonicalExternalId == canonicalId, "Canonical Podium ID was not preserved.");
    Require(first.RedirectsFrom.SequenceEqual(new[] { redirectId }), "Redirect IDs were not preserved deterministically.");

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        var records = await services.GetRequiredService<IRepository<IngestionRecord, Guid>>().GetListAsync();
        var imported = records.Where(x => x.Source == "podium7" && (x.ExternalId == canonicalId || x.ExternalId == redirectId)).ToArray();
        Require(imported.Length == 2, "Canonical + redirect Podium identities were not persisted.");
        Require(imported.All(x => x.ReconciledVehicleId == first.VehicleId), "Podium redirects did not converge to one BPT2 Vehicle.");
    });

    PodiumCatalogImportResultDto replay = null!;
    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeAdmin(services);
        replay = await services.GetRequiredService<IPodiumCatalogFeedAppService>()
            .ImportAsync(CreateInput(canonicalId, redirectId, suffix));
    });

    Require(replay.Replayed, "Replay was not detected.");
    Require(replay.VehicleId == first.VehicleId, "Replay created or selected a different Vehicle.");
    Console.WriteLine("PODIUM_REPLAY_AND_REDIRECT: PASS");

    var oldCanonical = $"veh_{Guid.NewGuid():N}";
    var newCanonical = $"veh_{Guid.NewGuid():N}";
    PodiumCatalogImportResultDto historical = null!;

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeAdmin(services);
        historical = await services.GetRequiredService<IPodiumCatalogFeedAppService>()
            .ImportAsync(CreateInput(oldCanonical, null, suffix + "h"));
    });

    PodiumCatalogImportResultDto redirected = null!;
    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeAdmin(services);
        redirected = await services.GetRequiredService<IPodiumCatalogFeedAppService>()
            .ImportAsync(CreateInput(newCanonical, oldCanonical, suffix + "changed-labels"));
    });

    Require(redirected.VehicleId == historical.VehicleId, "Historical Podium redirect was rematched instead of preserving the existing Vehicle link.");
    Require(redirected.Replayed, "Historical redirect convergence should reuse the existing mapped Vehicle.");
    Console.WriteLine("PODIUM_HISTORICAL_ID_CONTINUITY: PASS");

    await ExpectNotSupportedAsync(
        application.ServiceProvider,
        CreateInput($"veh_{Guid.NewGuid():N}", null, suffix, variant: null),
        "variant=null was projected despite required BPT2 VersionId.");

    await ExpectNotSupportedAsync(
        application.ServiceProvider,
        CreateInput($"veh_{Guid.NewGuid():N}", null, suffix, modelYearFrom: 2024, modelYearTo: 2025),
        "Model-year range was collapsed into scalar BPT2 ModelYear.");

    var unsupported = CreateInput($"veh_{Guid.NewGuid():N}", null, suffix);
    unsupported.ContractVersion = "3.0";
    await ExpectNotSupportedAsync(
        application.ServiceProvider,
        unsupported,
        "Unsupported Podium contract version was accepted.");

    Console.WriteLine("PODIUM_FAIL_CLOSED_CONTRACT: PASS");
}
finally
{
    await application.ShutdownAsync();
}

static PodiumCatalogVehicleInput CreateInput(
    string canonicalId,
    string? redirectId,
    string suffix,
    string? variant = "LTZ",
    int? modelYearFrom = 2025,
    int? modelYearTo = 2025)
{
    return new PodiumCatalogVehicleInput
    {
        ContractVersion = "2.0",
        Entity = new PodiumCatalogEntityInput
        {
            Id = canonicalId,
            Make = $"PodiumMake-{suffix}",
            Model = $"PodiumModel-{suffix}",
            Generation = "G1",
            Variant = variant,
            ModelYearFrom = modelYearFrom,
            ModelYearTo = modelYearTo
        },
        RedirectsFrom = redirectId is null ? Array.Empty<string>() : new[] { redirectId }
    };
}

static async Task ExpectNotSupportedAsync(
    IServiceProvider root,
    PodiumCatalogVehicleInput input,
    string failureMessage)
{
    var rejected = false;
    try
    {
        await InNewUnitOfWorkAsync(root, async services =>
        {
            using var principal = ChangeAdmin(services);
            await services.GetRequiredService<IPodiumCatalogFeedAppService>().ImportAsync(input);
        });
    }
    catch (NotSupportedException)
    {
        rejected = true;
    }
    catch (ArgumentException) when (input.Entity.Variant is null)
    {
        rejected = true;
    }

    Require(rejected, failureMessage);
}

static IDisposable ChangeAdmin(IServiceProvider services)
{
    var principalAccessor = services.GetRequiredService<ICurrentPrincipalAccessor>();
    var identity = new ClaimsIdentity(
        new[]
        {
            new Claim(AbpClaimTypes.UserId, Guid.NewGuid().ToString()),
            new Claim(AbpClaimTypes.Role, "admin")
        },
        authenticationType: "BPT2-PodiumFixture");
    return principalAccessor.Change(new ClaimsPrincipal(identity));
}

static async Task InNewUnitOfWorkAsync(IServiceProvider root, Func<IServiceProvider, Task> action)
{
    using var scope = root.CreateScope();
    var uowManager = scope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var uow = uowManager.Begin(requiresNew: true, isTransactional: true);
    await action(scope.ServiceProvider);
    await uow.CompleteAsync();
}

[DependsOn(
    typeof(AbpAutofacModule),
    typeof(BomPraTiCatalogModule),
    typeof(BomPraTiIngestionModule))]
public sealed class PodiumCatalogFeedFixtureModule : AbpModule
{
    public static string ConnectionString { get; set; } = null!;

    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpDbConnectionOptions>(options =>
        {
            options.ConnectionStrings.Default = ConnectionString;
        });
    }
}
