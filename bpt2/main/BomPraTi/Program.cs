using Volo.Abp;
using Volo.Abp.Autofac;

namespace BomPraTi;

public static class Program
{
    public static async Task Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.Host.UseAutofac();
        await builder.AddApplicationAsync<BomPraTiModule>();

        var app = builder.Build();
        await app.InitializeApplicationAsync();
        await app.RunAsync();
    }
}
