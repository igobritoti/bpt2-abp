using BomPraTi.Catalog.Contracts;
using BomPraTi.Catalog.Data;
using BomPraTi.Catalog.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;

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
        var powertrain = NormalizeOpaque(input.Powertrain);
        var transmission = NormalizeOpaque(input.Transmission);
        var bodyStyle = NormalizeOpaque(input.BodyStyle);

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

        vehicle.SynchronizeTechnicalIdentity(powertrain, transmission, bodyStyle);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return await _reader.GetAsync(vehicle.Id, cancellationToken)
            ?? throw new InvalidOperationException("Canonical Vehicle was saved but could not be read back.");
    }

    public async Task<VehicleRefDto> SynchronizeTechnicalIdentityAsync(
        Guid vehicleId,
        SynchronizeCanonicalVehicleTechnicalIdentityInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);

        var vehicle = await _dbContext.Vehicles
            .SingleOrDefaultAsync(x => x.Id == vehicleId, cancellationToken)
            ?? throw new EntityNotFoundException(typeof(Vehicle), vehicleId);

        vehicle.SynchronizeTechnicalIdentity(
            NormalizeOpaque(input.Powertrain),
            NormalizeOpaque(input.Transmission),
            NormalizeOpaque(input.BodyStyle));

        await _dbContext.SaveChangesAsync(cancellationToken);

        return await _reader.GetAsync(vehicle.Id, cancellationToken)
            ?? throw new InvalidOperationException("Canonical Vehicle was synchronized but could not be read back.");
    }

    public async Task SynchronizeExternalIdentifiersAsync(
        Guid vehicleId,
        SynchronizeCanonicalVehicleExternalIdentifiersInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);

        if (!await _dbContext.Vehicles.AnyAsync(x => x.Id == vehicleId, cancellationToken))
        {
            throw new EntityNotFoundException(typeof(Vehicle), vehicleId);
        }

        var authority = RequireOpaque(input.Authority, nameof(input.Authority));
        var identifiers = (input.Identifiers ?? Array.Empty<CanonicalVehicleExternalIdentifierInput>())
            .Select(x =>
            {
                ArgumentNullException.ThrowIfNull(x);
                return new ExternalIdentifierKey(
                    RequireOpaque(x.Namespace, nameof(x.Namespace)),
                    RequireOpaque(x.Value, nameof(x.Value)));
            })
            .Distinct()
            .OrderBy(x => x.Namespace, StringComparer.Ordinal)
            .ThenBy(x => x.Value, StringComparer.Ordinal)
            .ToArray();

        foreach (var identifier in identifiers)
        {
            var existingOwner = await _dbContext.VehicleExternalIdentifiers
                .SingleOrDefaultAsync(
                    x => x.Authority == authority &&
                         x.Namespace == identifier.Namespace &&
                         x.Value == identifier.Value,
                    cancellationToken);

            if (existingOwner is not null && existingOwner.VehicleId != vehicleId)
            {
                throw new InvalidOperationException(
                    $"External identifier '{authority}:{identifier.Namespace}:{identifier.Value}' is already linked to a different BPT2 Vehicle.");
            }
        }

        var current = await _dbContext.VehicleExternalIdentifiers
            .Where(x => x.VehicleId == vehicleId && x.Authority == authority)
            .ToListAsync(cancellationToken);
        var desired = identifiers.ToHashSet();

        _dbContext.VehicleExternalIdentifiers.RemoveRange(
            current.Where(x => !desired.Contains(new ExternalIdentifierKey(x.Namespace, x.Value))));

        var currentKeys = current
            .Select(x => new ExternalIdentifierKey(x.Namespace, x.Value))
            .ToHashSet();
        foreach (var identifier in identifiers.Where(x => !currentKeys.Contains(x)))
        {
            await _dbContext.VehicleExternalIdentifiers.AddAsync(
                new VehicleExternalIdentifier(
                    Guid.NewGuid(),
                    vehicleId,
                    authority,
                    identifier.Namespace,
                    identifier.Value),
                cancellationToken);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
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

    private static string? NormalizeOpaque(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }

    private static string RequireOpaque(string? value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value;
    }

    private sealed record ExternalIdentifierKey(string Namespace, string Value);
}
