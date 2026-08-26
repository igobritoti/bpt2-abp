using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class ListingPriceChange : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public decimal PreviousPrice { get; private set; }
    public decimal NewPrice { get; private set; }
    public DateTime ChangedAtUtc { get; private set; }

    private ListingPriceChange() { }

    public ListingPriceChange(
        Guid id,
        Guid listingId,
        decimal previousPrice,
        decimal newPrice,
        DateTime changedAtUtc) : base(id)
    {
        if (listingId == Guid.Empty) throw new ArgumentException("ListingId is required.", nameof(listingId));
        if (previousPrice <= 0) throw new ArgumentOutOfRangeException(nameof(previousPrice));
        if (newPrice <= 0) throw new ArgumentOutOfRangeException(nameof(newPrice));
        if (previousPrice == newPrice) throw new ArgumentException("Price change requires distinct values.", nameof(newPrice));

        ListingId = listingId;
        PreviousPrice = previousPrice;
        NewPrice = newPrice;
        ChangedAtUtc = DateTime.SpecifyKind(changedAtUtc, DateTimeKind.Utc);
    }
}
