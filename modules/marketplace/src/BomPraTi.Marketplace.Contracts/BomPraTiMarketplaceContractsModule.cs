using Volo.Abp.Application;
using Volo.Abp.Modularity;

namespace BomPraTi.Marketplace.Contracts;

[DependsOn(typeof(AbpDddApplicationContractsModule))]
public sealed class BomPraTiMarketplaceContractsModule : AbpModule
{
}
