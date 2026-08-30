using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public enum SavedSearchAlertDeliveryStatus
{
    Pending = 0,
    OutcomeUnknown = 1,
    Accepted = 2,
    Delivered = 3,
    PermanentFailed = 4,
    Suppressed = 5
}

public sealed class SavedSearchAlertDeliveryIntent : Entity<Guid>
{
    public Guid SavedSearchAlertMatchId { get; private set; }
    public Guid UserId { get; private set; }
    public string Channel { get; private set; } = string.Empty;
    public string IdempotencyKey { get; private set; } = string.Empty;
    public SavedSearchAlertDeliveryStatus Status { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime? LastAttemptAtUtc { get; private set; }

    private SavedSearchAlertDeliveryIntent() { }

    public SavedSearchAlertDeliveryIntent(
        Guid id,
        Guid savedSearchAlertMatchId,
        Guid userId,
        string channel,
        DateTime createdAtUtc)
        : base(id)
    {
        if (string.IsNullOrWhiteSpace(channel))
        {
            throw new ArgumentException("Delivery channel is required.", nameof(channel));
        }

        SavedSearchAlertMatchId = savedSearchAlertMatchId;
        UserId = userId;
        Channel = channel.Trim().ToLowerInvariant();
        IdempotencyKey = $"saved-search-alert:{id:N}";
        Status = SavedSearchAlertDeliveryStatus.Pending;
        CreatedAtUtc = DateTime.SpecifyKind(createdAtUtc, DateTimeKind.Utc);
    }

    public void MarkAttempted(DateTime attemptedAtUtc)
        => LastAttemptAtUtc = DateTime.SpecifyKind(attemptedAtUtc, DateTimeKind.Utc);

    public void MarkOutcomeUnknown(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        Status = SavedSearchAlertDeliveryStatus.OutcomeUnknown;
    }

    public void MarkAccepted(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        Status = SavedSearchAlertDeliveryStatus.Accepted;
    }

    public void MarkDelivered()
        => Status = SavedSearchAlertDeliveryStatus.Delivered;

    public void MarkPermanentFailed(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        Status = SavedSearchAlertDeliveryStatus.PermanentFailed;
    }

    public void MarkSuppressed()
        => Status = SavedSearchAlertDeliveryStatus.Suppressed;

    public void ReturnToPending(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        Status = SavedSearchAlertDeliveryStatus.Pending;
    }
}
