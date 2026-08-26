using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class FavoritePriceDropMatch : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public Guid ListingId { get; private set; }
    public Guid ListingPriceChangeId { get; private set; }
    public decimal PreviousPrice { get; private set; }
    public decimal NewPrice { get; private set; }
    public DateTime DetectedAtUtc { get; private set; }

    private FavoritePriceDropMatch() { }

    public FavoritePriceDropMatch(
        Guid id,
        Guid userId,
        Guid listingId,
        Guid listingPriceChangeId,
        decimal previousPrice,
        decimal newPrice,
        DateTime detectedAtUtc) : base(id)
    {
        if (userId == Guid.Empty) throw new ArgumentException("UserId is required.", nameof(userId));
        if (listingId == Guid.Empty) throw new ArgumentException("ListingId is required.", nameof(listingId));
        if (listingPriceChangeId == Guid.Empty) throw new ArgumentException("ListingPriceChangeId is required.", nameof(listingPriceChangeId));
        if (previousPrice <= 0) throw new ArgumentOutOfRangeException(nameof(previousPrice));
        if (newPrice <= 0 || newPrice >= previousPrice) throw new ArgumentOutOfRangeException(nameof(newPrice));

        UserId = userId;
        ListingId = listingId;
        ListingPriceChangeId = listingPriceChangeId;
        PreviousPrice = previousPrice;
        NewPrice = newPrice;
        DetectedAtUtc = DateTime.SpecifyKind(detectedAtUtc, DateTimeKind.Utc);
    }
}
