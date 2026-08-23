using BomPraTi.Media.Contracts;
using BomPraTi.Media.Data;
using BomPraTi.Media.Storage;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp.Application;
using Volo.Abp.Domain;
using Volo.Abp.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore.PostgreSql;
using Volo.Abp.Modularity;

namespace BomPraTi.Media;

[DependsOn(
    typeof(BomPraTiMediaContractsModule),
    typeof(AbpDddDomainModule),
    typeof(AbpDddApplicationModule),
    typeof(AbpEntityFrameworkCorePostgreSqlModule))]
public sealed class BomPraTiMediaModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddAbpDbContext<MediaDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
        });
        context.Services.AddSingleton<IMediaBlobStore, LocalMediaBlobStore>();

        Configure<AbpDbContextOptions>(options => options.UseNpgsql());
    }
}
