using BomPraTi.Catalog.Contracts;
using BomPraTi.Catalog.Data;
using BomPraTi.Catalog.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Catalog.Services;

[Authorize(Roles = "admin")]
public class CanonicalVehicleAdminAppService : ICanonicalVehicleAdminAppService, ITransientDependency
{
    private readonly CatalogDbContext _dbContext;
    private readonly IVehicleCatalogReader _reader;

    public CanonicalVehicleAdminAppService(CatalogDbContext dbContext, IVehicleCatalogReader reader)
    {
        _dbContext = dbContext;
        _reader = reader;
    }

    public async Task<VehicleRefDto> CreateAsync(
        CreateCanonicalVehicleInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);

        var brandName = RequireName(input.BrandName, 128, nameof(input.BrandName));
        var modelName = RequireName(input.ModelName, 128, nameof(input.ModelName));
        var versionName = RequireName(input.VersionName, 180, nameof(input.VersionName));
        var generationName = OptionalName(input.GenerationName, 128, nameof(input.GenerationName));

        if (generationName is null && (input.GenerationStartYear.HasValue || input.GenerationEndYear.HasValue))
        {
            throw new ArgumentException("GenerationName is required when generation years are provided.", nameof(input));
        }

        if (input.GenerationStartYear.HasValue && input.GenerationEndYear.HasValue &&
            input.GenerationStartYear.Value > input.GenerationEndYear.Value)
        {
            throw new ArgumentException("GenerationStartYear cannot be greater than GenerationEndYear.", nameof(input));
        }

        var brandNormalized = brandName.ToUpperInvariant();
        var brand = await _dbContext.Brands
            .SingleOrDefaultAsync(x => x.NormalizedName == brandNormalized, cancellationToken);
        if (brand is null)
        {
            brand = new Brand(Guid.NewGuid(), brandName);
            _dbContext.Brands.Add(brand);
        }

        var modelNormalized = modelName.ToUpperInvariant();
        var model = await _dbContext.Models
            .SingleOrDefaultAsync(
                x => x.BrandId == brand.Id && x.NormalizedName == modelNormalized,
                cancellationToken);
        if (model is null)
        {
            model = new VehicleModel(Guid.NewGuid(), brand.Id, modelName);
            _dbContext.Models.Add(model);
        }

        Generation? generation = null;
        if (generationName is not null)
        {
            generation = await _dbContext.Generations
                .FirstOrDefaultAsync(
                    x => x.ModelId == model.Id &&
                         x.Name == generationName &&
                         x.StartYear == input.GenerationStartYear &&
                         x.EndYear == input.GenerationEndYear,
                    cancellationToken);
            if (generation is null)
            {
                generation = new Generation(
                    Guid.NewGuid(),
                    model.Id,
                    generationName,
                    input.GenerationStartYear,
                    input.GenerationEndYear);
                _dbContext.Generations.Add(generation);
            }
        }

        var generationId = generation?.Id;
        var versionNormalized = versionName.ToUpperInvariant();
        var version = await _dbContext.Versions
            .SingleOrDefaultAsync(
                x => x.ModelId == model.Id &&
                     x.GenerationId == generationId &&
                     x.NormalizedName == versionNormalized,
                cancellationToken);
        if (version is null)
        {
            version = new VehicleVersion(Guid.NewGuid(), model.Id, generationId, versionName);
            _dbContext.Versions.Add(version);
        }

        var vehicle = await _dbContext.Vehicles
            .SingleOrDefaultAsync(
                x => x.BrandId == brand.Id &&
                     x.ModelId == model.Id &&
                     x.GenerationId == generationId &&
                     x.VersionId == version.Id &&
                     x.ModelYear == input.ModelYear,
                cancellationToken);
        if (vehicle is null)
        {
            vehicle = new Vehicle(
                Guid.NewGuid(),
                brand.Id,
                model.Id,
                generationId,
                version.Id,
                input.ModelYear);
            _dbContext.Vehicles.Add(vehicle);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return await _reader.GetAsync(vehicle.Id, cancellationToken)
            ?? throw new InvalidOperationException("Canonical Vehicle was saved but could not be read back.");
    }

    private static string RequireName(string? value, int maxLength, string parameterName)
    {
        var trimmed = value?.Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        if (trimmed.Length > maxLength)
        {
            throw new ArgumentException($"Value cannot exceed {maxLength} characters.", parameterName);
        }

        return trimmed;
    }

    private static string? OptionalName(string? value, int maxLength, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        if (trimmed.Length > maxLength)
        {
            throw new ArgumentException($"Value cannot exceed {maxLength} characters.", parameterName);
        }

        return trimmed;
    }
}
