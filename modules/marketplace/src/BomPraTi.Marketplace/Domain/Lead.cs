using Volo.Abp;
using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class Lead : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public Guid? UserId { get; private set; }
    public string Channel { get; private set; } = null!;
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime? ContactedAtUtc { get; private set; }
    public DateTime? ClosedAtUtc { get; private set; }
    public LeadOutcome? Outcome { get; private set; }

    private Lead() { }

    public Lead(Guid id, Guid listingId, Guid? userId, string channel, DateTime createdAtUtc) : base(id)
    {
        if (string.IsNullOrWhiteSpace(channel)) throw new ArgumentException("Lead channel is required.", nameof(channel));
        ListingId = listingId;
        UserId = userId;
        Channel = channel.Trim();
        CreatedAtUtc = DateTime.SpecifyKind(createdAtUtc, DateTimeKind.Utc);
    }

    public void MarkContacted(DateTime contactedAtUtc)
    {
        if (ContactedAtUtc.HasValue) return;
        ContactedAtUtc = DateTime.SpecifyKind(contactedAtUtc, DateTimeKind.Utc);
    }

    public void Close(LeadOutcome outcome, DateTime closedAtUtc)
    {
        if (Outcome.HasValue)
        {
            if (Outcome.Value == outcome) return;

            throw new BusinessException("BomPraTi.Marketplace:LeadOutcomeConflict")
                .WithData("LeadId", Id)
                .WithData("CurrentOutcome", Outcome.Value.ToString())
                .WithData("RequestedOutcome", outcome.ToString());
        }

        Outcome = outcome;
        ClosedAtUtc = DateTime.SpecifyKind(closedAtUtc, DateTimeKind.Utc);
    }
}
