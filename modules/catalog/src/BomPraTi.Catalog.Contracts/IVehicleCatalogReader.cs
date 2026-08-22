namespace BomPraTi.Catalog.Contracts;

public interface IVehicleCatalogReader
{
    Task<VehicleRefDto?> GetAsync(Guid vehicleId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<VehicleRefDto>> GetManyAsync(
        IReadOnlyCollection<Guid> vehicleIds,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Guid>> FindIdsAsync(VehicleCatalogSearchInput input, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<VehicleRefDto>> SearchAsync(
        VehicleCatalogSearchInput input,
        int take = 50,
        CancellationToken cancellationToken = default);
}
