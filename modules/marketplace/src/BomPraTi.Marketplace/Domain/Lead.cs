using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class Lead : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public Guid? UserId { get; private set; }
    public string Channel { get; private set; } = null!;
    public DateTime CreatedAtUtc { get; private set; }

    private Lead() { }

    public Lead(Guid id, Guid listingId, Guid? userId, string channel, DateTime createdAtUtc) : base(id)
    {
        if (string.IsNullOrWhiteSpace(channel)) throw new ArgumentException("Lead channel is required.", nameof(channel));
        ListingId = listingId;
        UserId = userId;
        Channel = channel.Trim();
        CreatedAtUtc = DateTime.SpecifyKind(createdAtUtc, DateTimeKind.Utc);
    }
}
