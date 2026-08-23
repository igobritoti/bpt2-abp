using Volo.Abp.Application;
using Volo.Abp.Modularity;

namespace BomPraTi.Ingestion.Contracts;

[DependsOn(typeof(AbpDddApplicationContractsModule))]
public sealed class BomPraTiIngestionContractsModule : AbpModule
{
}
