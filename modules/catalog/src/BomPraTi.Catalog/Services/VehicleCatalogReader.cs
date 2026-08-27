using BomPraTi.Catalog.Contracts;
using BomPraTi.Catalog.Data;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Catalog.Services;

public sealed class VehicleCatalogReader : IVehicleCatalogReader, ITransientDependency
{
    private readonly CatalogDbContext _dbContext;

    public VehicleCatalogReader(CatalogDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<VehicleRefDto?> GetAsync(Guid vehicleId, CancellationToken cancellationToken = default)
    {
        var vehicles = await GetManyAsync(new[] { vehicleId }, cancellationToken);
        return vehicles.SingleOrDefault();
    }

    public async Task<IReadOnlyList<VehicleRefDto>> GetManyAsync(
        IReadOnlyCollection<Guid> vehicleIds,
        CancellationToken cancellationToken = default)
    {
        var ids = vehicleIds.Distinct().ToArray();
        if (ids.Length == 0)
        {
            return Array.Empty<VehicleRefDto>();
        }

        var rows = await (
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            join version in _dbContext.Versions.AsNoTracking() on vehicle.VersionId equals version.Id
            join generation in _dbContext.Generations.AsNoTracking()
                on vehicle.GenerationId equals (Guid?)generation.Id into generationRows
            from generation in generationRows.DefaultIfEmpty()
            where ids.Contains(vehicle.Id)
            select new
            {
                vehicle.Id,
                vehicle.ModelYear,
                Brand = brand.Name,
                Model = model.Name,
                Generation = generation == null ? null : generation.Name,
                Version = version.Name
            })
            .ToListAsync(cancellationToken);

        return rows
            .Select(x => new VehicleRefDto(
                x.Id,
                x.Brand,
                x.Model,
                x.Generation,
                x.Version,
                x.ModelYear))
            .ToList();
    }

    public async Task<IReadOnlyList<Guid>> FindIdsAsync(
        VehicleCatalogSearchInput input,
        CancellationToken cancellationToken = default)
    {
        var vehicles =
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            select new
            {
                vehicle.Id,
                vehicle.ModelYear,
                Brand = brand.Name,
                Model = model.Name
            };

        if (!string.IsNullOrWhiteSpace(input.Brand))
        {
            var brand = input.Brand.Trim().ToLowerInvariant();
            vehicles = vehicles.Where(x => x.Brand.ToLower() == brand);
        }

        if (!string.IsNullOrWhiteSpace(input.Model))
        {
            var model = input.Model.Trim().ToLowerInvariant();
            vehicles = vehicles.Where(x => x.Model.ToLower() == model);
        }

        if (input.MinModelYear.HasValue)
        {
            vehicles = vehicles.Where(x => x.ModelYear.HasValue && x.ModelYear.Value >= input.MinModelYear.Value);
        }

        if (input.MaxModelYear.HasValue)
        {
            vehicles = vehicles.Where(x => x.ModelYear.HasValue && x.ModelYear.Value <= input.MaxModelYear.Value);
        }

        return await vehicles
            .OrderBy(x => x.Id)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Guid>> FindIdsByTextAsync(
        string query,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Array.Empty<Guid>();
        }

        var normalized = query.Trim().ToLowerInvariant();
        var vehicles =
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            join version in _dbContext.Versions.AsNoTracking() on vehicle.VersionId equals version.Id
            join generation in _dbContext.Generations.AsNoTracking()
                on vehicle.GenerationId equals (Guid?)generation.Id into generationRows
            from generation in generationRows.DefaultIfEmpty()
            where brand.Name.ToLower().Contains(normalized)
                || model.Name.ToLower().Contains(normalized)
                || version.Name.ToLower().Contains(normalized)
                || (generation != null && generation.Name.ToLower().Contains(normalized))
            orderby vehicle.Id
            select vehicle.Id;

        return await vehicles
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<VehicleRefDto>> SearchAsync(
        VehicleCatalogSearchInput input,
        int take = 50,
        CancellationToken cancellationToken = default,
        int skip = 0)
    {
        var vehicles =
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            join version in _dbContext.Versions.AsNoTracking() on vehicle.VersionId equals version.Id
            join generation in _dbContext.Generations.AsNoTracking()
                on vehicle.GenerationId equals (Guid?)generation.Id into generationRows
            from generation in generationRows.DefaultIfEmpty()
            select new
            {
                vehicle.Id,
                vehicle.ModelYear,
                Brand = brand.Name,
                Model = model.Name,
                Generation = generation == null ? null : generation.Name,
                Version = version.Name
            };

        if (!string.IsNullOrWhiteSpace(input.Brand))
        {
            var brand = input.Brand.Trim().ToLowerInvariant();
            vehicles = vehicles.Where(x => x.Brand.ToLower() == brand);
        }

        if (!string.IsNullOrWhiteSpace(input.Model))
        {
            var model = input.Model.Trim().ToLowerInvariant();
            vehicles = vehicles.Where(x => x.Model.ToLower() == model);
        }

        if (input.MinModelYear.HasValue)
        {
            vehicles = vehicles.Where(x => x.ModelYear.HasValue && x.ModelYear.Value >= input.MinModelYear.Value);
        }

        if (input.MaxModelYear.HasValue)
        {
            vehicles = vehicles.Where(x => x.ModelYear.HasValue && x.ModelYear.Value <= input.MaxModelYear.Value);
        }

        if (!string.IsNullOrWhiteSpace(input.Query))
        {
            var query = input.Query.Trim().ToLowerInvariant();
            vehicles = vehicles.Where(x =>
                x.Brand.ToLower().Contains(query)
                || x.Model.ToLower().Contains(query)
                || x.Version.ToLower().Contains(query)
                || (x.Generation != null && x.Generation.ToLower().Contains(query)));
        }

        var rows = await vehicles
            .OrderBy(x => x.Brand)
            .ThenBy(x => x.Model)
            .ThenBy(x => x.ModelYear)
            .ThenBy(x => x.Version)
            .ThenBy(x => x.Id)
            .Skip(Math.Max(skip, 0))
            .Take(Math.Clamp(take, 1, 100))
            .ToListAsync(cancellationToken);

        return rows
            .Select(x => new VehicleRefDto(
                x.Id,
                x.Brand,
                x.Model,
                x.Generation,
                x.Version,
                x.ModelYear))
            .ToList();
    }
}
