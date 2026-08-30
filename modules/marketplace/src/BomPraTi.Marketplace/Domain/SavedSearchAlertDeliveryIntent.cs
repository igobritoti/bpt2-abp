using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public enum SavedSearchAlertDeliveryStatus
{
    Pending = 0,
    InFlight = 1,
    RetryScheduled = 2,
    OutcomeUnknown = 3,
    Accepted = 4,
    Delivered = 5,
    PermanentFailed = 6,
    Suppressed = 7
}

public sealed class SavedSearchAlertDeliveryIntent : Entity<Guid>
{
    public Guid SavedSearchAlertMatchId { get; private set; }
    public Guid UserId { get; private set; }
    public string Channel { get; private set; } = string.Empty;
    public string IdempotencyKey { get; private set; } = string.Empty;
    public SavedSearchAlertDeliveryStatus Status { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public int AttemptCount { get; private set; }
    public DateTime? LastAttemptAtUtc { get; private set; }
    public DateTime? NextAttemptAtUtc { get; private set; }
    public DateTime? LeaseExpiresAtUtc { get; private set; }
    public string? RecipientFingerprint { get; private set; }
    public string? ProviderMessageId { get; private set; }

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

    public void MarkInFlight(DateTime attemptedAtUtc, DateTime leaseExpiresAtUtc)
    {
        AttemptCount++;
        LastAttemptAtUtc = DateTime.SpecifyKind(attemptedAtUtc, DateTimeKind.Utc);
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = DateTime.SpecifyKind(leaseExpiresAtUtc, DateTimeKind.Utc);
        Status = SavedSearchAlertDeliveryStatus.InFlight;
    }

    public bool BindRecipientFingerprint(string fingerprint)
    {
        if (string.IsNullOrWhiteSpace(fingerprint))
        {
            throw new ArgumentException("Recipient fingerprint is required.", nameof(fingerprint));
        }

        var normalized = fingerprint.Trim().ToUpperInvariant();
        if (RecipientFingerprint is null)
        {
            RecipientFingerprint = normalized;
            return true;
        }

        return string.Equals(RecipientFingerprint, normalized, StringComparison.Ordinal);
    }

    public void ScheduleRetry(DateTime nextAttemptAtUtc, bool outcomeUnknown = false)
    {
        NextAttemptAtUtc = DateTime.SpecifyKind(nextAttemptAtUtc, DateTimeKind.Utc);
        LeaseExpiresAtUtc = null;
        Status = outcomeUnknown
            ? SavedSearchAlertDeliveryStatus.OutcomeUnknown
            : SavedSearchAlertDeliveryStatus.RetryScheduled;
    }

    public void MarkAccepted(string providerMessageId)
    {
        if (string.IsNullOrWhiteSpace(providerMessageId))
        {
            throw new ArgumentException("Provider message id is required for accepted delivery.", nameof(providerMessageId));
        }

        ProviderMessageId = providerMessageId.Trim();
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.Accepted;
    }

    public void MarkDelivered()
    {
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.Delivered;
    }

    public void MarkPermanentFailed()
    {
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.PermanentFailed;
    }

    public void MarkSuppressed()
    {
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.Suppressed;
    }

    public void ReturnToPending(DateTime attemptedAtUtc)
    {
        LastAttemptAtUtc = DateTime.SpecifyKind(attemptedAtUtc, DateTimeKind.Utc);
        NextAttemptAtUtc = null;
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.Pending;
    }

    public void MarkAttempted(DateTime attemptedAtUtc)
        => LastAttemptAtUtc = DateTime.SpecifyKind(attemptedAtUtc, DateTimeKind.Utc);

    public void MarkOutcomeUnknown(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.OutcomeUnknown;
    }

    public void MarkAccepted(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.Accepted;
    }

    public void MarkPermanentFailed(DateTime attemptedAtUtc)
    {
        MarkAttempted(attemptedAtUtc);
        LeaseExpiresAtUtc = null;
        Status = SavedSearchAlertDeliveryStatus.PermanentFailed;
    }
}
