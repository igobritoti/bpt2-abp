using BomPraTi.Catalog.Contracts;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Guids;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class ListingCommandService : IListingCommandService, ITransientDependency
{
    private readonly IRepository<Listing, Guid> _listings;
    private readonly IRepository<ListingPriceChange, Guid> _priceChanges;
    private readonly IVehicleCatalogReader _vehicleCatalog;
    private readonly ICurrentUser _currentUser;
    private readonly IGuidGenerator _guidGenerator;
    private readonly SavedSearchAlertTrigger _savedSearchAlertTrigger;

    public ListingCommandService(
        IRepository<Listing, Guid> listings,
        IRepository<ListingPriceChange, Guid> priceChanges,
        IVehicleCatalogReader vehicleCatalog,
        ICurrentUser currentUser,
        IGuidGenerator guidGenerator,
        SavedSearchAlertTrigger savedSearchAlertTrigger)
    {
        _listings = listings;
        _priceChanges = priceChanges;
        _vehicleCatalog = vehicleCatalog;
        _currentUser = currentUser;
        _guidGenerator = guidGenerator;
        _savedSearchAlertTrigger = savedSearchAlertTrigger;
    }

    public async Task<ListingDto> CreateAsync(CreateListingInput input, CancellationToken cancellationToken = default)
    {
        var sellerId = GetSellerId();
        await RequireCanonicalVehicleAsync(input.VehicleId, cancellationToken);

        var listing = new Listing(
            _guidGenerator.Create(),
            sellerId,
            input.VehicleId,
            input.Title,
            input.Price,
            input.Description,
            input.ManufactureYear,
            input.MileageKm,
            input.Color,
            input.City,
            input.StateCode);

        await _listings.InsertAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
    }

    public async Task<ListingDto> UpdateAsync(
        Guid listingId,
        UpdateListingInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(input.ConcurrencyStamp);

        var listing = await GetOwnedAsync(listingId, cancellationToken);
        var previousPrice = listing.Price;
        var wasPublished = listing.Status == ListingStatus.Published;

        listing.ConcurrencyStamp = input.ConcurrencyStamp;
        listing.ChangeTitle(input.Title);
        listing.ChangePrice(input.Price);

        if (input.Description is not null
            || input.ManufactureYear.HasValue
            || input.MileageKm.HasValue
            || input.Color is not null
            || input.City is not null
            || input.StateCode is not null)
        {
            listing.ChangeDetails(
                input.Description ?? listing.Description,
                input.ManufactureYear ?? listing.ManufactureYear,
                input.MileageKm ?? listing.MileageKm,
                input.Color ?? listing.Color,
                input.City ?? listing.City,
                input.StateCode ?? listing.StateCode);
        }

        if (wasPublished && listing.Price != previousPrice)
        {
            await _priceChanges.InsertAsync(
                new ListingPriceChange(
                    _guidGenerator.Create(),
                    listing.Id,
                    previousPrice,
                    listing.Price,
                    DateTime.UtcNow),
                autoSave: false,
                cancellationToken: cancellationToken);
        }

        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
    }

    public async Task<ListingDto> PublishAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listing = await GetOwnedAsync(listingId, cancellationToken);
        await RequireCanonicalVehicleAsync(listing.VehicleId, cancellationToken);
        listing.Publish();
        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        await _savedSearchAlertTrigger.EnsureEnqueuedAsync(listing.Id, cancellationToken);
        return ToDto(listing);
    }

    public async Task<ListingDto> PauseAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listing = await GetOwnedAsync(listingId, cancellationToken);
        listing.Pause();
        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
    }

    public async Task<ListingDto> ArchiveAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listing = await GetOwnedAsync(listingId, cancellationToken);
        listing.Archive();
        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
    }

    private async Task<Listing> GetOwnedAsync(Guid listingId, CancellationToken cancellationToken)
    {
        var sellerId = GetSellerId();
        var listing = await _listings.GetAsync(listingId, includeDetails: false, cancellationToken: cancellationToken);
        listing.EnsureOwnedBy(sellerId);
        return listing;
    }

    private Guid GetSellerId()
    {
        return _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");
    }

    private async Task RequireCanonicalVehicleAsync(Guid vehicleId, CancellationToken cancellationToken)
    {
        if (await _vehicleCatalog.GetAsync(vehicleId, cancellationToken) is null)
        {
            throw new BusinessException("Marketplace:CanonicalVehicleNotFound")
                .WithData("VehicleId", vehicleId);
        }
    }

    private static ListingDto ToDto(Listing listing) => new(
        listing.Id,
        listing.SellerId,
        listing.VehicleId,
        listing.Title,
        listing.Price,
        listing.Description,
        listing.ManufactureYear,
        listing.MileageKm,
        listing.Color,
        listing.City,
        listing.StateCode,
        listing.Status.ToString(),
        listing.ConcurrencyStamp);
}
