using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;

namespace BomPraTi.Marketplace.Services;

[Authorize(Roles = "admin")]
public class ModerationListingCommandService : IModerationListingCommandService, ITransientDependency
{
    private readonly IRepository<Listing, Guid> _listings;

    public ModerationListingCommandService(IRepository<Listing, Guid> listings)
    {
        _listings = listings;
    }

    public async Task<ListingDto> WithdrawAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listing = await _listings.GetAsync(listingId, includeDetails: false, cancellationToken: cancellationToken);
        listing.Moderate();
        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
    }

    public async Task<ListingDto> RestoreAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var listing = await _listings.GetAsync(listingId, includeDetails: false, cancellationToken: cancellationToken);
        listing.RestoreFromModeration();
        await _listings.UpdateAsync(listing, autoSave: true, cancellationToken: cancellationToken);
        return ToDto(listing);
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
