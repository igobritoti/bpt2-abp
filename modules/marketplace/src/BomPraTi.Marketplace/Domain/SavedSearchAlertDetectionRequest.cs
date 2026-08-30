using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class SavedSearchAlertDetectionRequest : AggregateRoot<Guid>
{
    public Guid ListingId { get; private set; }
    public DateTime EnqueuedAtUtc { get; private set; }
    public DateTime? LastAttemptAtUtc { get; private set; }
    public DateTime? NextAttemptAtUtc { get; private set; }
    public DateTime? ProcessedAtUtc { get; private set; }

    private SavedSearchAlertDetectionRequest() { }

    public SavedSearchAlertDetectionRequest(Guid id, Guid listingId, DateTime enqueuedAtUtc) : base(id)
    {
        ListingId = listingId;
        EnqueuedAtUtc = DateTime.SpecifyKind(enqueuedAtUtc, DateTimeKind.Utc);
    }

    public void MarkProcessed(DateTime processedAtUtc)
    {
        ProcessedAtUtc ??= DateTime.SpecifyKind(processedAtUtc, DateTimeKind.Utc);
        NextAttemptAtUtc = null;
    }

    public void ScheduleRetry(DateTime nextAttemptAtUtc)
    {
        var scheduledAtUtc = DateTime.SpecifyKind(nextAttemptAtUtc, DateTimeKind.Utc);
        LastAttemptAtUtc = scheduledAtUtc;
        NextAttemptAtUtc = scheduledAtUtc;
    }
}
