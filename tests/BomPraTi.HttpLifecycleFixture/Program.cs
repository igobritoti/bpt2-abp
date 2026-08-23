using BomPraTi.Catalog;
using BomPraTi.Catalog.Domain;
using Microsoft.Extensions.DependencyInjection;
using Volo.Abp;
using Volo.Abp.Autofac;
using Volo.Abp.Data;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Modularity;
using Volo.Abp.Uow;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
}

HttpLifecycleFixtureModule.ConnectionString = connectionString;
using var application = await AbpApplicationFactory.CreateAsync<HttpLifecycleFixtureModule>(options => options.UseAutofac());
await application.InitializeAsync();

try
{
    var brandId = Guid.NewGuid();
    var modelId = Guid.NewGuid();
    var generationId = Guid.NewGuid();
    var versionId = Guid.NewGuid();
    var vehicleId = Guid.NewGuid();

    using var scope = application.ServiceProvider.CreateScope();
    var uowManager = scope.ServiceProvider.GetRequiredService<IUnitOfWorkManager>();
    using var uow = uowManager.Begin(requiresNew: true, isTransactional: true);

    await scope.ServiceProvider.GetRequiredService<IRepository<Brand, Guid>>()
        .InsertAsync(new Brand(brandId, $"HTTP-{brandId:N}"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<VehicleModel, Guid>>()
        .InsertAsync(new VehicleModel(modelId, brandId, "HTTP Lifecycle Model"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<Generation, Guid>>()
        .InsertAsync(new Generation(generationId, modelId, "HTTP-G1", 2020, null), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<VehicleVersion, Guid>>()
        .InsertAsync(new VehicleVersion(versionId, modelId, generationId, "HTTP Lifecycle Version"), autoSave: true);
    await scope.ServiceProvider.GetRequiredService<IRepository<Vehicle, Guid>>()
        .InsertAsync(new Vehicle(vehicleId, brandId, modelId, generationId, versionId, 2025), autoSave: true);

    await uow.CompleteAsync();
    Console.WriteLine(vehicleId);
}
finally
{
    await application.ShutdownAsync();
}

[DependsOn(typeof(AbpAutofacModule), typeof(BomPraTiCatalogModule))]
public sealed class HttpLifecycleFixtureModule : AbpModule
{
    public static string ConnectionString { get; set; } = null!;

    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpDbConnectionOptions>(options =>
        {
            options.ConnectionStrings.Default = ConnectionString;
        });
    }
}
