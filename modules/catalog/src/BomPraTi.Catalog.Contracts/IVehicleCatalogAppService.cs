using Volo.Abp.Application.Services;

namespace BomPraTi.Catalog.Contracts;

public interface IVehicleCatalogAppService : IApplicationService
{
    Task<VehicleRefDto?> GetAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<VehicleRefDto>> GetListAsync(
        VehicleCatalogSearchInput input,
        int take = 50,
        CancellationToken cancellationToken = default);
}
