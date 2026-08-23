using BomPraTi.Media.Contracts;
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
public sealed class ListingPhotoService : IListingPhotoService, ITransientDependency
{
    private readonly IRepository<Listing, Guid> _listings;
    private readonly IRepository<ListingPhoto, Guid> _photos;
    private readonly IMediaAssetReader _mediaAssets;
    private readonly ICurrentUser _currentUser;
    private readonly IGuidGenerator _guidGenerator;

    public ListingPhotoService(
        IRepository<Listing, Guid> listings,
        IRepository<ListingPhoto, Guid> photos,
        IMediaAssetReader mediaAssets,
        ICurrentUser currentUser,
        IGuidGenerator guidGenerator)
    {
        _listings = listings;
        _photos = photos;
        _mediaAssets = mediaAssets;
        _currentUser = currentUser;
        _guidGenerator = guidGenerator;
    }

    public async Task<IReadOnlyList<ListingPhotoDto>> AttachAsync(
        Guid listingId,
        AttachListingPhotoInput input,
        CancellationToken cancellationToken = default)
    {
        var listing = await GetOwnedListingAsync(listingId, cancellationToken);
        _ = listing;

        if (await _mediaAssets.GetAsync(input.MediaAssetId, cancellationToken) is null)
        {
            throw new BusinessException("Marketplace:MediaAssetNotFound")
                .WithData("MediaAssetId", input.MediaAssetId);
        }

        if (await _photos.AnyAsync(
                x => x.ListingId == listingId && x.MediaAssetId == input.MediaAssetId,
                cancellationToken: cancellationToken))
        {
            throw new BusinessException("Marketplace:MediaAssetAlreadyAttached")
                .WithData("MediaAssetId", input.MediaAssetId);
        }

        var existing = await _photos.GetListAsync(x => x.ListingId == listingId, cancellationToken: cancellationToken);
        var photo = new ListingPhoto(_guidGenerator.Create(), listingId, input.MediaAssetId, existing.Count);
        await _photos.InsertAsync(photo, autoSave: true, cancellationToken: cancellationToken);

        existing.Add(photo);
        return existing.OrderBy(x => x.SortOrder).ThenBy(x => x.Id).Select(ToDto).ToList();
    }

    public async Task<IReadOnlyList<ListingPhotoDto>> ReorderAsync(
        Guid listingId,
        ReorderListingPhotosInput input,
        CancellationToken cancellationToken = default)
    {
        await GetOwnedListingAsync(listingId, cancellationToken);
        var photos = await _photos.GetListAsync(x => x.ListingId == listingId, cancellationToken: cancellationToken);

        if (input.PhotoIds.Count != photos.Count || input.PhotoIds.Distinct().Count() != photos.Count)
        {
            throw new BusinessException("Marketplace:InvalidPhotoOrder");
        }

        var byId = photos.ToDictionary(x => x.Id);
        for (var i = 0; i < input.PhotoIds.Count; i++)
        {
            if (!byId.TryGetValue(input.PhotoIds[i], out var photo))
            {
                throw new BusinessException("Marketplace:InvalidPhotoOrder");
            }

            photo.MoveTo(i);
        }

        await _photos.UpdateManyAsync(photos, autoSave: true, cancellationToken: cancellationToken);
        return photos.OrderBy(x => x.SortOrder).Select(ToDto).ToList();
    }

    public async Task RemoveAsync(Guid listingId, Guid photoId, CancellationToken cancellationToken = default)
    {
        await GetOwnedListingAsync(listingId, cancellationToken);
        var photo = await _photos.GetAsync(photoId, includeDetails: false, cancellationToken: cancellationToken);
        if (photo.ListingId != listingId)
        {
            throw new BusinessException("Marketplace:PhotoNotInListing");
        }

        await _photos.DeleteAsync(photo, autoSave: true, cancellationToken: cancellationToken);

        var remaining = await _photos.GetListAsync(x => x.ListingId == listingId, cancellationToken: cancellationToken);
        var ordered = remaining.OrderBy(x => x.SortOrder).ThenBy(x => x.Id).ToList();
        for (var i = 0; i < ordered.Count; i++)
        {
            ordered[i].MoveTo(i);
        }
        await _photos.UpdateManyAsync(ordered, autoSave: true, cancellationToken: cancellationToken);
    }

    private async Task<Listing> GetOwnedListingAsync(Guid listingId, CancellationToken cancellationToken)
    {
        var sellerId = _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");
        var listing = await _listings.GetAsync(listingId, includeDetails: false, cancellationToken: cancellationToken);
        listing.EnsureOwnedBy(sellerId);
        return listing;
    }

    private static ListingPhotoDto ToDto(ListingPhoto photo) => new(photo.Id, photo.MediaAssetId, photo.SortOrder);
}
