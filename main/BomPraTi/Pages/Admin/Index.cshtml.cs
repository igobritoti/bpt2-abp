using BomPraTi.Catalog.Contracts;
using BomPraTi.Ingestion.Contracts;
using BomPraTi.Marketplace.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace BomPraTi.Pages.Admin;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private readonly IVehicleCatalogReader _vehicleCatalog;
    private readonly IModerationListingReportQuery _moderationReports;
    private readonly IIngestionCandidateAppService _ingestionCandidates;

    public int CanonicalVehicleCount { get; private set; }
    public int ModerationReportCount { get; private set; }
    public int PendingIngestionCount { get; private set; }

    public IndexModel(
        IVehicleCatalogReader vehicleCatalog,
        IModerationListingReportQuery moderationReports,
        IIngestionCandidateAppService ingestionCandidates)
    {
        _vehicleCatalog = vehicleCatalog;
        _moderationReports = moderationReports;
        _ingestionCandidates = ingestionCandidates;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        CanonicalVehicleCount = (await _vehicleCatalog.GetAllIdsAsync(cancellationToken)).Count;
        ModerationReportCount = (await _moderationReports.GetAsync(cancellationToken)).Count;
        PendingIngestionCount = (await _ingestionCandidates.GetPendingAsync(cancellationToken)).Count;
    }
}
