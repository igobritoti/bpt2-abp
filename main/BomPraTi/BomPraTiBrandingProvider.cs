using Microsoft.Extensions.Localization;
using BomPraTi.Localization;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Ui.Branding;

namespace BomPraTi;

[Dependency(ReplaceServices = true)]
public class BomPraTiBrandingProvider : DefaultBrandingProvider
{
    private IStringLocalizer<BomPraTiResource> _localizer;

    public BomPraTiBrandingProvider(IStringLocalizer<BomPraTiResource> localizer)
    {
        _localizer = localizer;
    }

    public override string AppName => _localizer["AppName"];
}
