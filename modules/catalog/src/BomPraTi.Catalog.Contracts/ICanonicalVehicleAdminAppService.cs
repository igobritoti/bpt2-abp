using Volo.Abp.Application.Services;

namespace BomPraTi.Catalog.Contracts;

public interface ICanonicalVehicleAdminAppService : IApplicationService
{
    Task<VehicleRefDto> CreateAsync(
        CreateCanonicalVehicleInput input,
        CancellationToken cancellationToken = default);
}
