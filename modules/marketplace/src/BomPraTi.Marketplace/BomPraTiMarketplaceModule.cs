using BomPraTi.Catalog.Contracts;
using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Sellers.Contracts;
using BomPraTi.Marketplace.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Volo.Abp.Application;
using Volo.Abp.Domain;
using Volo.Abp.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore.PostgreSql;
using Volo.Abp.Modularity;

namespace BomPraTi.Marketplace;

[DependsOn(
    typeof(BomPraTiMarketplaceContractsModule),
    typeof(BomPraTiCatalogContractsModule),
    typeof(BomPraTiMediaContractsModule),
    typeof(BomPraTiSellersContractsModule),
    typeof(AbpDddDomainModule),
    typeof(AbpDddApplicationModule),
    typeof(AbpEntityFrameworkCorePostgreSqlModule))]
public sealed class BomPraTiMarketplaceModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddAbpDbContext<MarketplaceDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
        });

        Configure<AbpDbContextOptions>(options => options.UseNpgsql());
        context.Services.Configure<SavedSearchAlertRunnerOptions>(options =>
        {
            options.Enabled = true;
            options.IdleDelay = TimeSpan.FromSeconds(15);
            options.MissingListingRetryDelay = TimeSpan.FromMinutes(5);
        });
        context.Services.AddHostedService<SavedSearchAlertRunnerBackgroundService>();
    }
}
