using BomPraTi.Catalog.Contracts;
using BomPraTi.Media.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using BomPraTi.Sellers.Contracts;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Application.Dtos;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

public sealed class PublicListingQuery : IPublicListingQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly IMediaAssetReader _mediaAssets;
    private readonly IVehicleCatalogReader _vehicleCatalog;
    private readonly ISellerPublicReader _sellers;

    public PublicListingQuery(
        MarketplaceDbContext dbContext,
        IMediaAssetReader mediaAssets,
        IVehicleCatalogReader vehicleCatalog,
        ISellerPublicReader sellers)
    {
        _dbContext = dbContext;
        _mediaAssets = mediaAssets;
        _vehicleCatalog = vehicleCatalog;
        _sellers = sellers;
    }

    public async Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listings = await GetManyAsync(new[] { listingId }, cancellationToken);
        return listings.SingleOrDefault();
    }

    public async Task<IReadOnlyList<PublicListingDto>> GetManyAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken = default)
    {
        var ids = listingIds.Distinct().ToArray();
        if (ids.Length == 0)
        {
            return Array.Empty<PublicListingDto>();
        }

        var rows = await ListingVisibility.PublicOnly(_dbContext.Listings.AsNoTracking())
            .Where(x => ids.Contains(x.Id))
            .OrderBy(x => x.Id)
            .Select(x => new ListingRow(
                x.Id,
                x.SellerId,
                x.VehicleId,
                x.Title,
                x.Price,
                x.Description,
                x.ManufactureYear,
                x.MileageKm,
                x.Color,
                x.City,
                x.StateCode))
            .ToListAsync(cancellationToken);

        return await ProjectRowsAsync(rows, cancellationToken);
    }

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        Guid? vehicleId = null,
        string? query = null,
        int skip = 0,
        int take = 20,
        CancellationToken cancellationToken = default)
    {
        return SearchAsync(
            new PublicListingSearchInput
            {
                VehicleId = vehicleId,
                Query = query,
                Skip = skip,
                Take = take
            },
            cancellationToken);
    }

    public async Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default)
    {
        var page = await SearchPageAsync(input, cancellationToken);
        return page.Items;
    }

    public async Task<PagedResultDto<PublicListingDto>> SearchPageAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);

        if (input.MinPrice.HasValue && input.MaxPrice.HasValue && input.MinPrice > input.MaxPrice)
        {
            return EmptyPage();
        }

        if (input.MinModelYear.HasValue && input.MaxModelYear.HasValue && input.MinModelYear > input.MaxModelYear)
        {
            return EmptyPage();
        }

        var listings = ListingVisibility.PublicOnly(_dbContext.Listings.AsNoTracking());

        if (input.VehicleId.HasValue)
        {
            listings = listings.Where(x => x.VehicleId == input.VehicleId.Value);
        }

        if (input.SellerId.HasValue)
        {
            listings = listings.Where(x => x.SellerId == input.SellerId.Value);
        }

        if (HasCatalogFilters(input))
        {
            var vehicleIds = await _vehicleCatalog.FindIdsAsync(
                new VehicleCatalogSearchInput(
                    input.Brand,
                    input.Model,
                    input.MinModelYear,
                    input.MaxModelYear),
                cancellationToken);

            if (vehicleIds.Count == 0)
            {
                return EmptyPage();
            }

            listings = listings.Where(x => vehicleIds.Contains(x.VehicleId));
        }

        if (!string.IsNullOrWhiteSpace(input.City))
        {
            var normalizedCity = input.City.Trim().ToLowerInvariant();
            listings = listings.Where(x => x.City.ToLower() == normalizedCity);
        }

        if (!string.IsNullOrWhiteSpace(input.StateCode))
        {
            var normalizedStateCode = input.StateCode.Trim().ToUpperInvariant();
            listings = listings.Where(x => x.StateCode == normalizedStateCode);
        }

        if (input.MinPrice.HasValue)
        {
            listings = listings.Where(x => x.Price >= input.MinPrice.Value);
        }

        if (input.MaxPrice.HasValue)
        {
            listings = listings.Where(x => x.Price <= input.MaxPrice.Value);
        }

        if (!string.IsNullOrWhiteSpace(input.Query))
        {
            var normalized = input.Query.Trim().ToLowerInvariant();
            listings = listings.Where(x => x.Title.ToLower().Contains(normalized));
        }

        var totalCount = await listings.LongCountAsync(cancellationToken);
        if (totalCount == 0)
        {
            return EmptyPage();
        }

        var boundedSkip = Math.Max(0, input.Skip);
        var boundedTake = Math.Clamp(input.Take, 1, 100);

        var rows = await listings
            .OrderBy(x => x.Id)
            .Skip(boundedSkip)
            .Take(boundedTake)
            .Select(x => new ListingRow(
                x.Id,
                x.SellerId,
                x.VehicleId,
                x.Title,
                x.Price,
                x.Description,
                x.ManufactureYear,
                x.MileageKm,
                x.Color,
                x.City,
                x.StateCode))
            .ToListAsync(cancellationToken);

        var items = await ProjectRowsAsync(rows, cancellationToken);
        return new PagedResultDto<PublicListingDto>(totalCount, items);
    }

    private static PagedResultDto<PublicListingDto> EmptyPage() =>
        new(0, Array.Empty<PublicListingDto>());

    private async Task<IReadOnlyList<PublicListingDto>> ProjectRowsAsync(
        IReadOnlyList<ListingRow> rows,
        CancellationToken cancellationToken)
    {
        if (rows.Count == 0)
        {
            return Array.Empty<PublicListingDto>();
        }

        var vehicles = await _vehicleCatalog.GetManyAsync(
            rows.Select(x => x.VehicleId).Distinct().ToArray(),
            cancellationToken);
        var vehiclesById = vehicles.ToDictionary(x => x.Id);

        var sellers = await _sellers.GetManyAsync(
            rows.Select(x => x.SellerId).Distinct().ToArray(),
            cancellationToken);
        var sellersById = sellers.ToDictionary(x => x.SellerId);

        var photos = await LoadPhotosAsync(rows.Select(x => x.Id).ToArray(), cancellationToken);
        return rows
            .Where(row => vehiclesById.ContainsKey(row.VehicleId))
            .Select(row => ToDto(
                row,
                vehiclesById[row.VehicleId],
                sellersById.GetValueOrDefault(row.SellerId),
                photos.GetValueOrDefault(row.Id) ?? Array.Empty<PublicListingPhotoDto>()))
            .ToList();
    }

    private static bool HasCatalogFilters(PublicListingSearchInput input)
    {
        return !string.IsNullOrWhiteSpace(input.Brand)
            || !string.IsNullOrWhiteSpace(input.Model)
            || input.MinModelYear.HasValue
            || input.MaxModelYear.HasValue;
    }

    private async Task<Dictionary<Guid, IReadOnlyList<PublicListingPhotoDto>>> LoadPhotosAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken)
    {
        if (listingIds.Count == 0)
        {
            return new Dictionary<Guid, IReadOnlyList<PublicListingPhotoDto>>();
        }

        var photoRows = await _dbContext.ListingPhotos
            .AsNoTracking()
            .Where(x => listingIds.Contains(x.ListingId))
            .OrderBy(x => x.SortOrder)
            .ThenBy(x => x.Id)
            .Select(x => new PhotoRow(x.Id, x.ListingId, x.MediaAssetId, x.SortOrder))
            .ToListAsync(cancellationToken);

        var mediaAssets = await _mediaAssets.GetManyAsync(
            photoRows.Select(x => x.MediaAssetId).Distinct().ToArray(),
            cancellationToken);
        var mediaById = mediaAssets.ToDictionary(x => x.Id);

        return photoRows
            .Where(x => mediaById.ContainsKey(x.MediaAssetId))
            .Select(x =>
            {
                var media = mediaById[x.MediaAssetId];
                return new
                {
                    x.ListingId,
                    Photo = new PublicListingPhotoDto(x.Id, x.MediaAssetId, media.ContentType, media.Length, x.SortOrder)
                };
            })
            .GroupBy(x => x.ListingId)
            .ToDictionary(
                group => group.Key,
                group => (IReadOnlyList<PublicListingPhotoDto>)group.Select(x => x.Photo).ToList());
    }

    private static PublicListingDto ToDto(
        ListingRow row,
        VehicleRefDto vehicle,
        SellerPublicContactDto? seller,
        IReadOnlyList<PublicListingPhotoDto> photos) =>
        new(
            row.Id,
            row.VehicleId,
            new PublicListingVehicleDto(
                vehicle.Id,
                vehicle.Brand,
                vehicle.Model,
                vehicle.Generation,
                vehicle.Version,
                vehicle.ModelYear),
            new PublicListingSellerDto(row.SellerId, seller?.DisplayName, seller?.WhatsAppNumber),
            row.Title,
            row.Price,
            row.Description,
            row.ManufactureYear,
            row.MileageKm,
            row.Color,
            row.City,
            row.StateCode,
            photos);

    private sealed record ListingRow(
        Guid Id,
        Guid SellerId,
        Guid VehicleId,
        string Title,
        decimal Price,
        string Description,
        int? ManufactureYear,
        int? MileageKm,
        string? Color,
        string City,
        string StateCode);

    private sealed record PhotoRow(Guid Id, Guid ListingId, Guid MediaAssetId, int SortOrder);
}
