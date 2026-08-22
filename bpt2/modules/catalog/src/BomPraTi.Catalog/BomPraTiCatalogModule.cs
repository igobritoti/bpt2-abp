using BomPraTi.Catalog.Contracts;
using BomPraTi.Catalog.Data;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp.Application;
using Volo.Abp.Domain;
using Volo.Abp.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore.PostgreSql;
using Volo.Abp.Modularity;

namespace BomPraTi.Catalog;

[DependsOn(
    typeof(BomPraTiCatalogContractsModule),
    typeof(AbpDddDomainModule),
    typeof(AbpDddApplicationModule),
    typeof(AbpEntityFrameworkCorePostgreSqlModule))]
public sealed class BomPraTiCatalogModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddAbpDbContext<CatalogDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
        });

        Configure<AbpDbContextOptions>(options => options.UseNpgsql());
    }
}
