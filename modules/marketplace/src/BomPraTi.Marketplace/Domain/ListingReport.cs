using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class ListingReport : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public Guid ListingId { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    private ListingReport() { }

    public ListingReport(Guid id, Guid userId, Guid listingId, DateTime createdAtUtc) : base(id)
    {
        UserId = userId;
        ListingId = listingId;
        CreatedAtUtc = createdAtUtc;
    }
}
