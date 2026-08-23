using BomPraTi.Catalog.Contracts;
using BomPraTi.Ingestion.Contracts;
using BomPraTi.Ingestion.Data;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp.Application;
using Volo.Abp.Domain;
using Volo.Abp.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore.PostgreSql;
using Volo.Abp.Modularity;

namespace BomPraTi.Ingestion;

[DependsOn(
    typeof(BomPraTiIngestionContractsModule),
    typeof(BomPraTiCatalogContractsModule),
    typeof(AbpDddDomainModule),
    typeof(AbpDddApplicationModule),
    typeof(AbpEntityFrameworkCorePostgreSqlModule))]
public sealed class BomPraTiIngestionModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddAbpDbContext<IngestionDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
        });

        Configure<AbpDbContextOptions>(options => options.UseNpgsql());
    }
}
