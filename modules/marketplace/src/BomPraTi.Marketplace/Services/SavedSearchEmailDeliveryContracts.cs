namespace BomPraTi.Marketplace.Services;

public sealed record SavedSearchEmailRecipient(string Email);

public sealed record SavedSearchEmailMessage(
    Guid IntentId,
    Guid ListingId,
    Guid SavedSearchId,
    string RecipientEmail,
    string IdempotencyKey);

public enum SavedSearchEmailSendOutcome
{
    Accepted = 0,
    TransientFailure = 1,
    PermanentFailure = 2,
    OutcomeUnknown = 3
}

public sealed record SavedSearchEmailSendResult(
    SavedSearchEmailSendOutcome Outcome,
    string? ProviderMessageId = null);

public interface ISavedSearchEmailRecipientResolver
{
    Task<SavedSearchEmailRecipient?> ResolveVerifiedAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}

public interface ISavedSearchEmailTransport
{
    Task<SavedSearchEmailSendResult> SendAsync(
        SavedSearchEmailMessage message,
        CancellationToken cancellationToken = default);
}
