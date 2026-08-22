using Volo.Abp.Application;
using Volo.Abp.Modularity;

namespace BomPraTi.Sellers.Contracts;

[DependsOn(typeof(AbpDddApplicationContractsModule))]
public sealed class BomPraTiSellersContractsModule : AbpModule
{
}
