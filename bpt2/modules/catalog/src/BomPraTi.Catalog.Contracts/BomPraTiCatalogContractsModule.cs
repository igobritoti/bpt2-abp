using Volo.Abp.Application;
using Volo.Abp.Modularity;

namespace BomPraTi.Catalog.Contracts;

[DependsOn(typeof(AbpDddApplicationContractsModule))]
public sealed class BomPraTiCatalogContractsModule : AbpModule
{
}
