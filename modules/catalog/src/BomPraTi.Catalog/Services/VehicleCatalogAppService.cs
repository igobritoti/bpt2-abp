using BomPraTi.Catalog.Contracts;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Catalog.Services;

[AllowAnonymous]
public sealed class VehicleCatalogAppService : IVehicleCatalogAppService, ITransientDependency
{
    private readonly IVehicleCatalogReader _reader;

    public VehicleCatalogAppService(IVehicleCatalogReader reader)
    {
        _reader = reader;
    }

    public Task<VehicleRefDto?> GetAsync(Guid vehicleId, CancellationToken cancellationToken = default) =>
        _reader.GetAsync(vehicleId, cancellationToken);

    public Task<IReadOnlyList<VehicleRefDto>> GetListAsync(
        VehicleCatalogSearchInput input,
        int take = 50,
        CancellationToken cancellationToken = default) =>
        _reader.SearchAsync(input, take, cancellationToken);
}
