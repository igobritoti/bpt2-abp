using BomPraTi.Catalog.Contracts;
using BomPraTi.Ingestion.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Volo.Abp.Domain.Entities;

namespace BomPraTi.Pages.Ingestao;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private const int MaxVehicleMatches = 20;

    private readonly IIngestionCandidateAppService _candidates;
    private readonly IVehicleCatalogReader _vehicleCatalog;

    public IReadOnlyList<IngestionRecordDto> Pending { get; private set; } = [];
    public IReadOnlyList<VehicleRefDto> VehicleMatches { get; private set; } = [];

    [BindProperty(SupportsGet = true)]
    public string? VehicleQuery { get; set; }

    [BindProperty]
    public Guid RecordId { get; set; }

    [BindProperty]
    public Guid VehicleId { get; set; }

    public IndexModel(
        IIngestionCandidateAppService candidates,
        IVehicleCatalogReader vehicleCatalog)
    {
        _candidates = candidates;
        _vehicleCatalog = vehicleCatalog;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        await LoadPageAsync(cancellationToken);
    }

    public async Task<IActionResult> OnPostReconcileAsync(CancellationToken cancellationToken)
    {
        if (RecordId == Guid.Empty)
        {
            ModelState.AddModelError(nameof(RecordId), "Registro de ingestão inválido.");
        }

        if (VehicleId == Guid.Empty)
        {
            ModelState.AddModelError(nameof(VehicleId), "Informe um VehicleId canônico válido.");
        }

        if (!ModelState.IsValid)
        {
            await LoadPageAsync(cancellationToken);
            return Page();
        }

        try
        {
            await _candidates.ReconcileAsync(RecordId, VehicleId, cancellationToken);
        }
        catch (EntityNotFoundException)
        {
            ModelState.AddModelError(nameof(VehicleId), "Registro de ingestão ou Vehicle canônico não encontrado.");
            await LoadPageAsync(cancellationToken);
            return Page();
        }

        return RedirectToPage(new { VehicleQuery });
    }

    private async Task LoadPageAsync(CancellationToken cancellationToken)
    {
        Pending = await _candidates.GetPendingAsync(cancellationToken);
        VehicleMatches = await FindVehicleMatchesAsync(cancellationToken);
    }

    private async Task<IReadOnlyList<VehicleRefDto>> FindVehicleMatchesAsync(CancellationToken cancellationToken)
    {
        var query = VehicleQuery?.Trim();
        if (string.IsNullOrEmpty(query))
        {
            return [];
        }

        var ids = await _vehicleCatalog.FindIdsByTextAsync(query, cancellationToken);
        if (ids.Count == 0)
        {
            return [];
        }

        return await _vehicleCatalog.GetManyAsync(ids.Take(MaxVehicleMatches).ToArray(), cancellationToken);
    }
}
