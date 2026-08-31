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

        // PERF: Direct projection into VehicleRefDto in EF Core query eliminates intermediate anonymous object allocation
        return await (
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            join version in _dbContext.Versions.AsNoTracking() on vehicle.VersionId equals version.Id
            join generation in _dbContext.Generations.AsNoTracking()
                on vehicle.GenerationId equals (Guid?)generation.Id into generationRows
            from generation in generationRows.DefaultIfEmpty()
            where ids.Contains(vehicle.Id)
            select new VehicleRefDto(
                vehicle.Id,
                brand.Name,
                model.Name,
                generation == null ? null : generation.Name,
                version.Name,
                vehicle.ModelYear,
                vehicle.Powertrain,
                vehicle.Transmission,
                vehicle.BodyStyle))
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Guid>> FindIdsAsync(
        VehicleCatalogSearchInput input,
        CancellationToken cancellationToken = default)
    {
        // PERF: Avoid joining Brands/Models when no brand or model filters are provided, avoiding SQL JOIN overhead and anonymous type allocations
        var query = _dbContext.Vehicles.AsNoTracking();

        if (input.MinModelYear.HasValue)
        {
            query = query.Where(x => x.ModelYear.HasValue && x.ModelYear.Value >= input.MinModelYear.Value);
        }

        if (input.MaxModelYear.HasValue)
        {
            query = query.Where(x => x.ModelYear.HasValue && x.ModelYear.Value <= input.MaxModelYear.Value);
        }

        if (!string.IsNullOrWhiteSpace(input.Brand))
        {
            var brandTerm = input.Brand.Trim().ToLowerInvariant();
            query = from vehicle in query
                    join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
                    where brand.Name.ToLower() == brandTerm
                    select vehicle;
        }

        if (!string.IsNullOrWhiteSpace(input.Model))
        {
            var modelTerm = input.Model.Trim().ToLowerInvariant();
            query = from vehicle in query
                    join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
                    where model.Name.ToLower() == modelTerm
                    select vehicle;
        }

        return await query
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

        var normalized = NormalizePresentationQuery(query);
        var vehicles =
            from vehicle in _dbContext.Vehicles.AsNoTracking()
            join brand in _dbContext.Brands.AsNoTracking() on vehicle.BrandId equals brand.Id
            join model in _dbContext.Models.AsNoTracking() on vehicle.ModelId equals model.Id
            join version in _dbContext.Versions.AsNoTracking() on vehicle.VersionId equals version.Id
            join generation in _dbContext.Generations.AsNoTracking()
                on vehicle.GenerationId equals (Guid?)generation.Id into generationRows
            from generation in generationRows.DefaultIfEmpty()
            where brand.Name.ToLower().Replace("-", " ").Contains(normalized)
                || model.Name.ToLower().Replace("-", " ").Contains(normalized)
                || version.Name.ToLower().Replace("-", " ").Contains(normalized)
                || (generation != null && generation.Name.ToLower().Replace("-", " ").Contains(normalized))
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
                vehicle.Powertrain,
                vehicle.Transmission,
                vehicle.BodyStyle,
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
            var query = NormalizePresentationQuery(input.Query);
            vehicles = vehicles.Where(x =>
                x.Brand.ToLower().Replace("-", " ").Contains(query)
                || x.Model.ToLower().Replace("-", " ").Contains(query)
                || x.Version.ToLower().Replace("-", " ").Contains(query)
                || (x.Generation != null && x.Generation.ToLower().Replace("-", " ").Contains(query)));
        }

        // PERF: Direct projection into VehicleRefDto in EF Core query eliminates intermediate anonymous object allocation
        return await vehicles
            .OrderBy(x => x.Brand)
            .ThenBy(x => x.Model)
            .ThenBy(x => x.ModelYear)
            .ThenBy(x => x.Version)
            .ThenBy(x => x.Id)
            .Skip(Math.Max(skip, 0))
            .Take(Math.Clamp(take, 1, 100))
            .Select(x => new VehicleRefDto(
                x.Id,
                x.Brand,
                x.Model,
                x.Generation,
                x.Version,
                x.ModelYear,
                x.Powertrain,
                x.Transmission,
                x.BodyStyle))
            .ToListAsync(cancellationToken);
    }

    private static string NormalizePresentationQuery(string value) =>
        value.Trim().ToLowerInvariant().Replace('-', ' ');
}
