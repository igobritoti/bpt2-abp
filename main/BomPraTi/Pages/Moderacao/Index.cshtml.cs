using BomPraTi.Marketplace.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace BomPraTi.Pages.Moderacao;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private readonly IModerationListingReportQuery _reportQuery;

    public IReadOnlyList<ModerationListingReportDto> Reports { get; private set; } = [];

    public IndexModel(IModerationListingReportQuery reportQuery)
    {
        _reportQuery = reportQuery;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Reports = await _reportQuery.GetAsync(cancellationToken);
    }
}
