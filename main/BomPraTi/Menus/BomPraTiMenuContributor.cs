using Microsoft.Extensions.DependencyInjection;
using Volo.Abp.UI.Navigation;
using Volo.Abp.Users;

namespace BomPraTi.Menus;

public sealed class BomPraTiMenuContributor : IMenuContributor
{
    public Task ConfigureMenuAsync(MenuConfigurationContext context)
    {
        if (context.Menu.Name != StandardMenus.Main)
        {
            return Task.CompletedTask;
        }

        var currentUser = context.ServiceProvider.GetRequiredService<ICurrentUser>();
        if (!currentUser.IsInRole("admin"))
        {
            return Task.CompletedTask;
        }

        context.Menu.AddItem(
            new ApplicationMenuItem(
                "BomPraTi.AdminOperations",
                "Operações",
                "/admin"));

        return Task.CompletedTask;
    }
}
