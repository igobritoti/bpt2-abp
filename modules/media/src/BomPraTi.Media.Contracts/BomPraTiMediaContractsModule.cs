using Volo.Abp.Application;
using Volo.Abp.Modularity;

namespace BomPraTi.Media.Contracts;

[DependsOn(typeof(AbpDddApplicationContractsModule))]
public sealed class BomPraTiMediaContractsModule : AbpModule
{
}
