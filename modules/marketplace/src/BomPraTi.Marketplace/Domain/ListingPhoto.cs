using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class ListingPhoto : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public Guid MediaAssetId { get; private set; }
    public int SortOrder { get; private set; }

    private ListingPhoto() { }

    public ListingPhoto(Guid id, Guid listingId, Guid mediaAssetId, int sortOrder) : base(id)
    {
        if (sortOrder < 0) throw new ArgumentOutOfRangeException(nameof(sortOrder));
        ListingId = listingId;
        MediaAssetId = mediaAssetId;
        SortOrder = sortOrder;
    }

    public void MoveTo(int sortOrder)
    {
        if (sortOrder < 0) throw new ArgumentOutOfRangeException(nameof(sortOrder));
        SortOrder = sortOrder;
    }
}
