using BomPraTi.Catalog;
using BomPraTi.Marketplace;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Services;
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

if (args.Length != 2 || !Guid.TryParse(args[1], out var listingId))
{
    throw new ArgumentException("Usage: <state|replay> <listingId>");
}

PriceDropFixtureModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<PriceDropFixtureModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    if (string.Equals(args[0], "replay", StringComparison.OrdinalIgnoreCase))
    {
        using var replayScope = application.ServiceProvider.CreateScope();
        var replayUowManager = replayScope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
        using var replayUow = replayUowManager.Begin(requiresNew: true, isTransactional: true);
        var replayDbContext = replayScope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
        var priceChange = await replayDbContext.ListingPriceChanges
            .AsNoTracking()
            .Where(x => x.ListingId == listingId)
            .OrderByDescending(x => x.ChangedAtUtc)
            .ThenByDescending(x => x.Id)
            .FirstAsync();

        await replayScope.ServiceProvider.GetRequiredService<FavoritePriceDropDetector>()
            .DetectAsync(priceChange);
        await replayUow.CompleteAsync();
    }
    else if (!string.Equals(args[0], "state", StringComparison.OrdinalIgnoreCase))
    {
        throw new ArgumentException("Command must be state or replay.");
    }

    using var stateScope = application.ServiceProvider.CreateScope();
    var stateUowManager = stateScope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var stateUow = stateUowManager.Begin(requiresNew: true, isTransactional: false);
    var stateDbContext = stateScope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();
    var rows = await stateDbContext.FavoritePriceDropMatches
        .AsNoTracking()
        .Where(x => x.ListingId == listingId)
        .OrderBy(x => x.DetectedAtUtc)
        .ThenBy(x => x.Id)
        .Select(x => new { x.UserId, x.PreviousPrice, x.NewPrice })
        .ToListAsync();

    await stateUow.CompleteAsync();
    Console.WriteLine(string.Join(
        ";",
        rows.Select(x => $"{x.UserId:N}|{x.PreviousPrice:0.00}>{x.NewPrice:0.00}")));
}
finally
{
    await application.ShutdownAsync();
}

[DependsOn(typeof(AbpAutofacModule), typeof(BomPraTiCatalogModule), typeof(BomPraTiMarketplaceModule))]
public sealed class PriceDropFixtureModule : AbpModule
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
