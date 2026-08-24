using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace BomPraTi.Pages.Admin;

[Authorize(Roles = "admin")]
public class IndexModel : PageModel
{
    public void OnGet()
    {
    }
}
