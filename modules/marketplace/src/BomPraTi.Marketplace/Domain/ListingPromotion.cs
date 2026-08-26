using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class ListingPromotion : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public DateTime StartsAtUtc { get; private set; }
    public DateTime EndsAtUtc { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    private ListingPromotion() { }

    public ListingPromotion(
        Guid id,
        Guid listingId,
        DateTime startsAtUtc,
        DateTime endsAtUtc,
        DateTime createdAtUtc) : base(id)
    {
        var normalizedStart = DateTime.SpecifyKind(startsAtUtc, DateTimeKind.Utc);
        var normalizedEnd = DateTime.SpecifyKind(endsAtUtc, DateTimeKind.Utc);
        if (normalizedEnd <= normalizedStart)
        {
            throw new ArgumentException("Promotion end must be after start.", nameof(endsAtUtc));
        }

        ListingId = listingId;
        StartsAtUtc = normalizedStart;
        EndsAtUtc = normalizedEnd;
        CreatedAtUtc = DateTime.SpecifyKind(createdAtUtc, DateTimeKind.Utc);
    }

    public bool IsActive(DateTime utcNow)
    {
        var normalizedNow = DateTime.SpecifyKind(utcNow, DateTimeKind.Utc);
        return StartsAtUtc <= normalizedNow && normalizedNow < EndsAtUtc;
    }
}
