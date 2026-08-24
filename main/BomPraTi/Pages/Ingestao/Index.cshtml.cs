using BomPraTi.Ingestion.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Volo.Abp.Domain.Entities;

namespace BomPraTi.Pages.Ingestao;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private readonly IIngestionCandidateAppService _candidates;

    public IReadOnlyList<IngestionRecordDto> Pending { get; private set; } = [];

    [BindProperty]
    public Guid RecordId { get; set; }

    [BindProperty]
    public Guid VehicleId { get; set; }

    public IndexModel(IIngestionCandidateAppService candidates)
    {
        _candidates = candidates;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        await LoadPendingAsync(cancellationToken);
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
            await LoadPendingAsync(cancellationToken);
            return Page();
        }

        try
        {
            await _candidates.ReconcileAsync(RecordId, VehicleId, cancellationToken);
        }
        catch (EntityNotFoundException)
        {
            ModelState.AddModelError(nameof(VehicleId), "Registro de ingestão ou Vehicle canônico não encontrado.");
            await LoadPendingAsync(cancellationToken);
            return Page();
        }

        return RedirectToPage();
    }

    private async Task LoadPendingAsync(CancellationToken cancellationToken)
    {
        Pending = await _candidates.GetPendingAsync(cancellationToken);
    }
}
