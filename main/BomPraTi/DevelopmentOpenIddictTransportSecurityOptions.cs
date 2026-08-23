using Microsoft.Extensions.Options;
using OpenIddict.Server.AspNetCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi;

[ExposeServices(typeof(IConfigureOptions<OpenIddictServerAspNetCoreOptions>))]
public sealed class DevelopmentOpenIddictTransportSecurityOptions :
    IConfigureOptions<OpenIddictServerAspNetCoreOptions>,
    ITransientDependency
{
    private readonly IWebHostEnvironment _environment;
    private readonly IConfiguration _configuration;

    public DevelopmentOpenIddictTransportSecurityOptions(
        IWebHostEnvironment environment,
        IConfiguration configuration)
    {
        _environment = environment;
        _configuration = configuration;
    }

    public void Configure(OpenIddictServerAspNetCoreOptions options)
    {
        if (_environment.IsDevelopment()
            && !Convert.ToBoolean(_configuration["AuthServer:RequireHttpsMetadata"]))
        {
            options.DisableTransportSecurityRequirement = true;
        }
    }
}
