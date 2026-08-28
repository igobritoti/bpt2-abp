using BomPraTi.Catalog;
using BomPraTi.Catalog.Domain;
using BomPraTi.Marketplace;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using BomPraTi.Marketplace.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp;
using Volo.Abp.Autofac;
using Volo.Abp.Data;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Modularity;
using Volo.Abp.Uow;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
}

HttpLifecycleFixtureModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<HttpLifecycleFixtureModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    using var scope = application.ServiceProvider.CreateScope();
    var uowManager = scope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var uow = uowManager.Begin(requiresNew: true, isTransactional: true);

    if (args.Length > 0 && string.Equals(args[0], "lead", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 2 || !Guid.TryParse(args[1], out var listingId))
        {
            throw new ArgumentException("Usage: lead <listingId>");
        }

        var leadId = Guid.NewGuid();
        await scope.ServiceProvider.GetRequiredService<IRepository<Lead, Guid>>()
            .InsertAsync(new Lead(leadId, listingId, null, "WhatsApp", DateTime.UtcNow), autoSave: true);
        await uow.CompleteAsync();
        Console.WriteLine(leadId);
        return;
    }

    if (args.Length > 0 && string.Equals(args[0], "reassign-listing", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 3 || !Guid.TryParse(args[1], out var listingId) || !Guid.TryParse(args[2], out var sellerId))
        {
            throw new ArgumentException("Usage: reassign-listing <listingId> <sellerId>");
        }

        var dbContext = scope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
        var affected = await dbContext.Database.ExecuteSqlInterpolatedAsync(
            $"UPDATE \"MarketplaceListings\" SET \"SellerId\" = {sellerId} WHERE \"Id\" = {listingId}");
        if (affected != 1)
        {
            throw new InvalidOperationException($"Expected exactly one Listing to be reassigned, affected={affected}.");
        }

        await uow.CompleteAsync();
        Console.WriteLine(listingId);
        return;
    }

    if (args.Length > 0 && string.Equals(args[0], "promotion", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 3 || !Guid.TryParse(args[1], out var listingId))
        {
            throw new ArgumentException("Usage: promotion <listingId> <active|future|expired>");
        }

        var now = DateTime.UtcNow;
        var (startsAtUtc, endsAtUtc) = args[2].Trim().ToLowerInvariant() switch
        {
            "active" => (now.AddHours(-1), now.AddHours(1)),
            "future" => (now.AddHours(1), now.AddHours(2)),
            "expired" => (now.AddHours(-2), now.AddHours(-1)),
            _ => throw new ArgumentException("Promotion state must be active, future or expired.")
        };

        var promotionId = Guid.NewGuid();
        await scope.ServiceProvider.GetRequiredService<IRepository<ListingPromotion, Guid>>()
            .InsertAsync(
                new ListingPromotion(promotionId, listingId, startsAtUtc, endsAtUtc, now),
                autoSave: true);
        await uow.CompleteAsync();
        Console.WriteLine(promotionId);
        return;
    }

    if (args.Length > 0 && string.Equals(args[0], "price-history", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 2 || !Guid.TryParse(args[1], out var listingId))
        {
            throw new ArgumentException("Usage: price-history <listingId>");
        }

        var dbContext = scope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
        var changes = await dbContext.ListingPriceChanges
            .AsNoTracking()
            .Where(x => x.ListingId == listingId)
            .OrderBy(x => x.ChangedAtUtc)
            .ThenBy(x => x.Id)
            .Select(x => new { x.PreviousPrice, x.NewPrice })
            .ToListAsync();

        await uow.CompleteAsync();
        Console.WriteLine(string.Join(";", changes.Select(x => $"{x.PreviousPrice:0.00}>{x.NewPrice:0.00}")));
        return;
    }

    if (args.Length > 0 && string.Equals(args[0], "alert-trigger-rollback", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 2 || !Guid.TryParse(args[1], out var listingId))
        {
            throw new ArgumentException("Usage: alert-trigger-rollback <listingId>");
        }

        var listingRepository = scope.ServiceProvider.GetRequiredService<IRepository<Listing, Guid>>();
        var listing = await listingRepository.GetAsync(listingId, includeDetails: false);
        listing.Publish(DateTime.UtcNow);
        await listingRepository.UpdateAsync(listing, autoSave: true);
        await scope.ServiceProvider.GetRequiredService<SavedSearchAlertTrigger>().EnsureEnqueuedAsync(listingId);

        var requestRepository = scope.ServiceProvider.GetRequiredService<IRepository<SavedSearchAlertDetectionRequest, Guid>>();
        var staged = await requestRepository.CountAsync(x => x.ListingId == listingId);
        if (staged != 1)
        {
            throw new InvalidOperationException($"Expected one staged alert request before rollback, count={staged}.");
        }

        await uow.RollbackAsync();
        Console.WriteLine("ROLLBACK_STAGED");
        return;
    }

    if (args.Length > 0 && string.Equals(args[0], "alert-trigger-state", StringComparison.OrdinalIgnoreCase))
    {
        if (args.Length != 2 || !Guid.TryParse(args[1], out var listingId))
        {
            throw new ArgumentException("Usage: alert-trigger-state <listingId>");
        }

        var dbContext = scope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
        var status = await dbContext.Listings
            .AsNoTracking()
            .Where(x => x.Id == listingId)
            .Select(x => x.Status)
            .SingleAsync();
        var requests = await dbContext.SavedSearchAlertDetectionRequests
            .AsNoTracking()
            .Where(x => x.ListingId == listingId)
            .Select(x => x.ProcessedAtUtc)
            .ToListAsync();

        await uow.CompleteAsync();
        var processed = requests.Count == 1 && requests[0].HasValue ? "processed" : "pending";
        Console.WriteLine($"{status}|{requests.Count}|{processed}");
        return;
    }

    var brandId = Guid.NewGuid();
    var modelId = Guid.NewGuid();
    var generationId = Guid.NewGuid();
    var versionId = Guid.NewGuid();
    var vehicleId = Guid.NewGuid();

    await scope.ServiceProvider.GetRequiredService<IRepository<Brand, Guid>>()
        .InsertAsync(new Brand(brandId, $"HTTP-{brandId:N}"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<VehicleModel, Guid>>()
        .InsertAsync(new VehicleModel(modelId, brandId, "HTTP Lifecycle Model"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<Generation, Guid>>()
        .InsertAsync(new Generation(generationId, modelId, "HTTP-G1", 2020, null), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<VehicleVersion, Guid>>()
        .InsertAsync(new VehicleVersion(versionId, modelId, generationId, "HTTP Lifecycle Version"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<Vehicle, Guid>>()
        .InsertAsync(new Vehicle(vehicleId, brandId, modelId, generationId, versionId, 2025), autoSave: true);

    await uow.CompleteAsync();
    Console.WriteLine(vehicleId);
}
finally
{
    await application.ShutdownAsync();
}

[DependsOn(typeof(AbpAutofacModule), typeof(BomPraTiCatalogModule), typeof(BomPraTiMarketplaceModule))]
public sealed class HttpLifecycleFixtureModule : AbpModule
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
