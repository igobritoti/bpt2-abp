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
    using var scope = application.ServiceProvider.CreateScope();
    var uowManager = scope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var uow = uowManager.Begin(requiresNew: true, isTransactional: true);
    var dbContext = scope.ServiceProvider.GetRequiredService<MarketplaceDbContext>();

    if (string.Equals(args[0], "replay", StringComparison.OrdinalIgnoreCase))
    {
        var priceChange = await dbContext.ListingPriceChanges
            .Where(x => x.ListingId == listingId)
            .OrderByDescending(x => x.ChangedAtUtc)
            .ThenByDescending(x => x.Id)
            .FirstAsync();
        await scope.ServiceProvider.GetRequiredService<FavoritePriceDropDetector>()
            .DetectAsync(priceChange);
        await dbContext.SaveChangesAsync();
    }
    else if (!string.Equals(args[0], "state", StringComparison.OrdinalIgnoreCase))
    {
        throw new ArgumentException("Command must be state or replay.");
    }

    var rows = await dbContext.FavoritePriceDropMatches
        .AsNoTracking()
        .Where(x => x.ListingId == listingId)
        .OrderBy(x => x.DetectedAtUtc)
        .ThenBy(x => x.Id)
        .Select(x => new { x.UserId, x.PreviousPrice, x.NewPrice })
        .ToListAsync();

    await uow.CompleteAsync();
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
