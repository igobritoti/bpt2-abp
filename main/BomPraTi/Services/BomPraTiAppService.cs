using BomPraTi.Localization;
using Volo.Abp.Application.Services;

namespace BomPraTi.Services;

/* Inherit your application services from this class. */
public abstract class BomPraTiAppService : ApplicationService
{
    protected BomPraTiAppService()
    {
        LocalizationResource = typeof(BomPraTiResource);
    }
}