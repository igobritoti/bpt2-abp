using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class SavedSearchEmailProviderEvent : Entity<Guid>
{
    public string Provider { get; private set; } = string.Empty;
    public string ProviderEventId { get; private set; } = string.Empty;
    public string ProviderMessageId { get; private set; } = string.Empty;
    public string EventType { get; private set; } = string.Empty;
    public DateTime ReceivedAtUtc { get; private set; }

    private SavedSearchEmailProviderEvent() { }

    public SavedSearchEmailProviderEvent(
        Guid id,
        string provider,
        string providerEventId,
        string providerMessageId,
        string eventType,
        DateTime receivedAtUtc) : base(id)
    {
        if (string.IsNullOrWhiteSpace(provider)) throw new ArgumentException("Provider is required.", nameof(provider));
        if (string.IsNullOrWhiteSpace(providerEventId)) throw new ArgumentException("Provider event id is required.", nameof(providerEventId));
        if (string.IsNullOrWhiteSpace(providerMessageId)) throw new ArgumentException("Provider message id is required.", nameof(providerMessageId));
        if (string.IsNullOrWhiteSpace(eventType)) throw new ArgumentException("Event type is required.", nameof(eventType));

        Provider = provider.Trim().ToLowerInvariant();
        ProviderEventId = providerEventId.Trim();
        ProviderMessageId = providerMessageId.Trim();
        EventType = eventType.Trim().ToLowerInvariant();
        ReceivedAtUtc = DateTime.SpecifyKind(receivedAtUtc, DateTimeKind.Utc);
    }
}
