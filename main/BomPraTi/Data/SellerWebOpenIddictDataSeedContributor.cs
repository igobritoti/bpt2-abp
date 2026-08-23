using OpenIddict.Abstractions;
using Volo.Abp.Data;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Uow;

namespace BomPraTi.Data;

public class SellerWebOpenIddictDataSeedContributor : IDataSeedContributor, ITransientDependency
{
    private readonly IConfiguration _configuration;
    private readonly IOpenIddictApplicationManager _applicationManager;

    public SellerWebOpenIddictDataSeedContributor(
        IConfiguration configuration,
        IOpenIddictApplicationManager applicationManager)
    {
        _configuration = configuration;
        _applicationManager = applicationManager;
    }

    [UnitOfWork]
    public virtual async Task SeedAsync(DataSeedContext context)
    {
        var section = _configuration.GetSection("OpenIddict:Applications:BomPraTi_SellerWeb");
        var clientId = section["ClientId"];
        var rootUrl = section["RootUrl"]?.TrimEnd('/');

        if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(rootUrl))
        {
            return;
        }

        if (await _applicationManager.FindByClientIdAsync(clientId) is not null)
        {
            return;
        }

        var application = new OpenIddictApplicationDescriptor
        {
            ClientId = clientId,
            ClientType = OpenIddictConstants.ClientTypes.Public,
            ConsentType = OpenIddictConstants.ConsentTypes.Implicit,
            DisplayName = "Bom Pra Ti Seller Web"
        };

        application.RedirectUris.Add(new Uri($"{rootUrl}/vender/callback"));
        application.PostLogoutRedirectUris.Add(new Uri($"{rootUrl}/vender"));

        application.Permissions.Add(OpenIddictConstants.Permissions.Endpoints.Authorization);
        application.Permissions.Add(OpenIddictConstants.Permissions.Endpoints.EndSession);
        application.Permissions.Add(OpenIddictConstants.Permissions.Endpoints.Token);
        application.Permissions.Add(OpenIddictConstants.Permissions.GrantTypes.AuthorizationCode);
        application.Permissions.Add(OpenIddictConstants.Permissions.ResponseTypes.Code);
        application.Permissions.Add(OpenIddictConstants.Permissions.Scopes.Email);
        application.Permissions.Add(OpenIddictConstants.Permissions.Scopes.Profile);
        application.Permissions.Add(OpenIddictConstants.Permissions.Scopes.Roles);
        application.Permissions.Add(OpenIddictConstants.Permissions.Prefixes.Scope + "BomPraTi");
        application.Requirements.Add(OpenIddictConstants.Requirements.Features.ProofKeyForCodeExchange);

        await _applicationManager.CreateAsync(application);
    }
}
