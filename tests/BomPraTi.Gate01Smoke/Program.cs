using System.Security.Claims;
using BomPraTi.Catalog;
using BomPraTi.Catalog.Domain;
using BomPraTi.Media;
using BomPraTi.Marketplace;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Domain;
using BomPraTi.Sellers;
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

Gate01SmokeModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<Gate01SmokeModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    var sellerA = Guid.NewGuid();
    var sellerB = Guid.NewGuid();
    var brandId = Guid.NewGuid();
    var modelId = Guid.NewGuid();
    var generationId = Guid.NewGuid();
    var versionId = Guid.NewGuid();
    var vehicleId = Guid.NewGuid();
    Guid listingId = Guid.Empty;
    string listingConcurrencyStamp = string.Empty;

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        await services.GetRequiredService<IRepository<Brand, Guid>>()
            .InsertAsync(new Brand(brandId, $"Gate-{brandId:N}"), autoSave: true);
        await services.GetRequiredService<IRepository<VehicleModel, Guid>>()
            .InsertAsync(new VehicleModel(modelId, brandId, "Gate Model"), autoSave: true);
        await services.GetRequiredService<IRepository<Generation, Guid>>()
            .InsertAsync(new Generation(generationId, modelId, "G1", 2020, null), autoSave: true);
        await services.GetRequiredService<IRepository<VehicleVersion, Guid>>()
            .InsertAsync(new VehicleVersion(versionId, modelId, generationId, "Gate Version"), autoSave: true);
        await services.GetRequiredService<IRepository<Vehicle, Guid>>()
            .InsertAsync(new Vehicle(vehicleId, brandId, modelId, generationId, versionId, 2025), autoSave: true);
    });

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeUser(services, sellerA);
        var commands = services.GetRequiredService<IListingCommandService>();
        var created = await commands.CreateAsync(new CreateListingInput(
            vehicleId,
            "Gate 01 Listing",
            100_000m,
            "Gate 01 description",
            2024,
            12_000,
            "Prata",
            "Porto Alegre",
            "RS"));
        listingId = created.Id;
        listingConcurrencyStamp = created.ConcurrencyStamp;
        Require(created.SellerId == sellerA, "CreateListing did not bind ownership to the authenticated seller.");
        Require(created.Status == nameof(ListingStatus.Draft), "New listing was not Draft.");
        Require(!string.IsNullOrWhiteSpace(created.ConcurrencyStamp), "CreateListing did not return a concurrency stamp.");
    });

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        var publicQuery = services.GetRequiredService<IPublicListingQuery>();
        Require(await publicQuery.GetAsync(listingId) is null, "Public query exposed a Draft listing.");
    });
    Console.WriteLine("G01_PUBLIC_DRAFT: PASS");

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeUser(services, sellerB);
        var commands = services.GetRequiredService<IListingCommandService>();
        var rejected = false;
        try
        {
            await commands.PublishAsync(listingId);
        }
        catch (InvalidOperationException)
        {
            rejected = true;
        }
        Require(rejected, "A different seller was allowed to publish the listing.");
    });
    Console.WriteLine("G01_OWNERSHIP: PASS");

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeUser(services, sellerA);
        var commands = services.GetRequiredService<IListingCommandService>();
        var published = await commands.PublishAsync(listingId);
        listingConcurrencyStamp = published.ConcurrencyStamp;
    });

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        var publicQuery = services.GetRequiredService<IPublicListingQuery>();
        Require(await publicQuery.GetAsync(listingId) is not null, "Published listing was not returned publicly.");
    });

    var staleStamp = listingConcurrencyStamp;
    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        using var principal = ChangeUser(services, sellerA);
        var commands = services.GetRequiredService<IListingCommandService>();
        var updated = await commands.UpdateAsync(
            listingId,
            new UpdateListingInput("Gate 01 Listing updated", 101_000m, staleStamp));
        Require(updated.ConcurrencyStamp != staleStamp, "Application update did not rotate the concurrency stamp.");
        listingConcurrencyStamp = updated.ConcurrencyStamp;
    });

    var conflict = false;
    try
    {
        await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
        {
            using var principal = ChangeUser(services, sellerA);
            var commands = services.GetRequiredService<IListingCommandService>();
            await commands.UpdateAsync(
                listingId,
                new UpdateListingInput("Gate 01 stale update", 102_000m, staleStamp));
        });
    }
    catch (AbpDbConcurrencyException)
    {
        conflict = true;
    }

    Require(conflict, "Stale application-service Listing update was accepted.");
    Console.WriteLine("G01_CONCURRENCY: PASS");

    var rollbackBrandId = Guid.NewGuid();
    var rollbackListingId = Guid.NewGuid();
    var rollbackTriggered = false;
    try
    {
        await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
        {
            await services.GetRequiredService<IRepository<Brand, Guid>>()
                .InsertAsync(new Brand(rollbackBrandId, $"Rollback-{rollbackBrandId:N}"), autoSave: true);
            await services.GetRequiredService<IRepository<Listing, Guid>>()
                .InsertAsync(new Listing(rollbackListingId, sellerA, vehicleId, "Rollback Listing", 90_000m), autoSave: true);
            throw new InvalidOperationException("intentional rollback probe");
        });
    }
    catch (InvalidOperationException ex) when (ex.Message == "intentional rollback probe")
    {
        rollbackTriggered = true;
    }

    Require(rollbackTriggered, "Rollback probe did not execute.");

    await InNewUnitOfWorkAsync(application.ServiceProvider, async services =>
    {
        var brand = await services.GetRequiredService<IRepository<Brand, Guid>>().FindAsync(rollbackBrandId);
        var listing = await services.GetRequiredService<IRepository<Listing, Guid>>().FindAsync(rollbackListingId);
        Require(brand is null && listing is null, "Multi-module UoW left persisted state after rollback.");
    });
    Console.WriteLine("G01_MULTI_MODULE_ROLLBACK: PASS");
}
finally
{
    await application.ShutdownAsync();
}

static IDisposable ChangeUser(IServiceProvider services, Guid userId)
{
    var principalAccessor = services.GetRequiredService<ICurrentPrincipalAccessor>();
    var identity = new ClaimsIdentity(
        new[] { new Claim(AbpClaimTypes.UserId, userId.ToString()) },
        authenticationType: "BPT2-Gate01");
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
    typeof(BomPraTiMediaModule),
    typeof(BomPraTiSellersModule),
    typeof(BomPraTiMarketplaceModule))]
public sealed class Gate01SmokeModule : AbpModule
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
