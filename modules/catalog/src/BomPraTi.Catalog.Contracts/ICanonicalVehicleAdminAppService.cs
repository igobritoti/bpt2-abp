using Volo.Abp.Application.Services;

namespace BomPraTi.Catalog.Contracts;

public interface ICanonicalVehicleAdminAppService : IApplicationService
{
    Task<VehicleRefDto> CreateAsync(
        CreateCanonicalVehicleInput input,
        CancellationToken cancellationToken = default);

    Task<VehicleRefDto> SynchronizeTechnicalIdentityAsync(
        Guid vehicleId,
        SynchronizeCanonicalVehicleTechnicalIdentityInput input,
        CancellationToken cancellationToken = default);

    Task SynchronizeExternalIdentifiersAsync(
        Guid vehicleId,
        SynchronizeCanonicalVehicleExternalIdentifiersInput input,
        CancellationToken cancellationToken = default);
}
