using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class Favorite : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public Guid ListingId { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    private Favorite() { }

    public Favorite(Guid id, Guid userId, Guid listingId, DateTime createdAtUtc) : base(id)
    {
        UserId = userId;
        ListingId = listingId;
        CreatedAtUtc = createdAtUtc;
    }
}
