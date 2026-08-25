using BomPraTi.Catalog.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace BomPraTi.Pages.Catalogo;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    private readonly ICanonicalVehicleAdminAppService _catalog;

    [BindProperty]
    public string BrandName { get; set; } = string.Empty;

    [BindProperty]
    public string ModelName { get; set; } = string.Empty;

    [BindProperty]
    public string? GenerationName { get; set; }

    [BindProperty]
    public int? GenerationStartYear { get; set; }

    [BindProperty]
    public int? GenerationEndYear { get; set; }

    [BindProperty]
    public string VersionName { get; set; } = string.Empty;

    [BindProperty]
    public int? ModelYear { get; set; }

    public Guid? CreatedVehicleId { get; private set; }

    public IndexModel(ICanonicalVehicleAdminAppService catalog)
    {
        _catalog = catalog;
    }

    public void OnGet(Guid? vehicleId = null)
    {
        CreatedVehicleId = vehicleId;
    }

    public async Task<IActionResult> OnPostCreateAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(BrandName))
        {
            ModelState.AddModelError(nameof(BrandName), "Informe a marca.");
        }

        if (string.IsNullOrWhiteSpace(ModelName))
        {
            ModelState.AddModelError(nameof(ModelName), "Informe o modelo.");
        }

        if (string.IsNullOrWhiteSpace(VersionName))
        {
            ModelState.AddModelError(nameof(VersionName), "Informe a versão.");
        }

        if (string.IsNullOrWhiteSpace(GenerationName) &&
            (GenerationStartYear.HasValue || GenerationEndYear.HasValue))
        {
            ModelState.AddModelError(nameof(GenerationName), "Informe a geração quando houver anos da geração.");
        }

        if (GenerationStartYear.HasValue && GenerationEndYear.HasValue &&
            GenerationStartYear.Value > GenerationEndYear.Value)
        {
            ModelState.AddModelError(nameof(GenerationEndYear), "O ano final da geração deve ser maior ou igual ao inicial.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var vehicle = await _catalog.CreateAsync(
                new CreateCanonicalVehicleInput
                {
                    BrandName = BrandName,
                    ModelName = ModelName,
                    GenerationName = GenerationName,
                    GenerationStartYear = GenerationStartYear,
                    GenerationEndYear = GenerationEndYear,
                    VersionName = VersionName,
                    ModelYear = ModelYear
                },
                cancellationToken);

            return RedirectToPage(new { vehicleId = vehicle.Id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
    }
}
