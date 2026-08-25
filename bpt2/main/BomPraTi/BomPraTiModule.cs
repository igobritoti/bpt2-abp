using BomPraTi.Catalog;
using BomPraTi.Sellers;
using Volo.Abp.AspNetCore.Mvc;
using Volo.Abp.Autofac;
using Volo.Abp.Modularity;

namespace BomPraTi;

[DependsOn(
    typeof(AbpAspNetCoreMvcModule),
    typeof(AbpAutofacModule),
    typeof(BomPraTiCatalogModule),
    typeof(BomPraTiSellersModule))]
public sealed class BomPraTiModule : AbpModule
{
}
