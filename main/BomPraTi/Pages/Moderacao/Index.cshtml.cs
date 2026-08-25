using BomPraTi.Marketplace.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace BomPraTi.Pages.Moderacao;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private readonly IModerationListingReportQuery _reportQuery;
    private readonly IModerationListingCommandService _listingCommands;

    public IReadOnlyList<ModerationListingReportDto> Reports { get; private set; } = [];

    public IndexModel(
        IModerationListingReportQuery reportQuery,
        IModerationListingCommandService listingCommands)
    {
        _reportQuery = reportQuery;
        _listingCommands = listingCommands;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Reports = await _reportQuery.GetAsync(cancellationToken);
    }

    public async Task<IActionResult> OnPostWithdrawAsync(Guid listingId, CancellationToken cancellationToken)
    {
        await _listingCommands.WithdrawAsync(listingId, cancellationToken);
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostRestoreAsync(Guid listingId, CancellationToken cancellationToken)
    {
        await _listingCommands.RestoreAsync(listingId, cancellationToken);
        return RedirectToPage();
    }
}
