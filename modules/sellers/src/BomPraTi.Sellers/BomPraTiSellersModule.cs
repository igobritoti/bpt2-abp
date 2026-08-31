using BomPraTi.Sellers.Contracts;
using BomPraTi.Sellers.Data;
using BomPraTi.Sellers.Services;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp.Application;
using Volo.Abp.Domain;
using Volo.Abp.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore.PostgreSql;
using Volo.Abp.Modularity;

namespace BomPraTi.Sellers;

[DependsOn(
    typeof(BomPraTiSellersContractsModule),
    typeof(AbpDddDomainModule),
    typeof(AbpDddApplicationModule),
    typeof(AbpEntityFrameworkCorePostgreSqlModule))]
public sealed class BomPraTiSellersModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddAbpDbContext<SellersDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
        });

        context.Services.AddTransient<ISellerPublicQuery, SellerPublicQueryAppService>();

        Configure<AbpDbContextOptions>(options => options.UseNpgsql());
    }
}
