using System.Text.Json;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;

var connection = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION")
    ?? throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
var outputPath = Environment.GetEnvironmentVariable("BPT_SAVED_SEARCH_EMAIL_DELIVERY_OUTPUT")
    ?? "artifacts/saved-search-email-delivery-baseline.json";

var options = new DbContextOptionsBuilder<MarketplaceDbContext>()
    .UseNpgsql(connection)
    .Options;

var now = new DateTime(2026, 8, 29, 18, 0, 0, DateTimeKind.Utc);
var provider = new FakeProvider();
var scenarios = new List<object>();

static void Require(bool condition, string message)
{
    if (!condition) throw new InvalidOperationException(message);
}

async Task<SavedSearchAlertDeliveryIntent?> EnsureIntentAsync(
    Guid matchId,
    Guid userId,
    RecipientSnapshot recipient)
{
    if (!recipient.EmailConfirmed || !recipient.ExternalEmailOptIn)
    {
        return null;
    }

    await using var db = new MarketplaceDbContext(options);
    var existing = await db.SavedSearchAlertDeliveryIntents
        .SingleOrDefaultAsync(x => x.SavedSearchAlertMatchId == matchId && x.Channel == "email");
    if (existing is not null)
    {
        return existing;
    }

    var intent = new SavedSearchAlertDeliveryIntent(Guid.NewGuid(), matchId, userId, "email", now);
    db.SavedSearchAlertDeliveryIntents.Add(intent);
    await db.SaveChangesAsync();
    return intent;
}

async Task<SavedSearchAlertDeliveryIntent> LoadAsync(Guid id)
{
    await using var db = new MarketplaceDbContext(options);
    return await db.SavedSearchAlertDeliveryIntents.SingleAsync(x => x.Id == id);
}

async Task DispatchAsync(Guid intentId, RecipientSnapshot recipient, FakeOutcome outcome)
{
    await using var db = new MarketplaceDbContext(options);
    var intent = await db.SavedSearchAlertDeliveryIntents.SingleAsync(x => x.Id == intentId);

    if (!recipient.EmailConfirmed || !recipient.ExternalEmailOptIn)
    {
        intent.MarkSuppressed();
        await db.SaveChangesAsync();
        return;
    }

    var result = provider.Send(recipient.Email, intent.IdempotencyKey, outcome);
    switch (result)
    {
        case FakeOutcome.Accepted:
            intent.MarkAccepted(now.AddMinutes(1));
            break;
        case FakeOutcome.TimeoutUnknown:
            intent.MarkOutcomeUnknown(now.AddMinutes(1));
            break;
        case FakeOutcome.PermanentRejected:
            intent.MarkPermanentFailed(now.AddMinutes(1));
            break;
        case FakeOutcome.TransientFailed:
            intent.ReturnToPending(now.AddMinutes(1));
            break;
        default:
            throw new ArgumentOutOfRangeException(nameof(outcome));
    }
    await db.SaveChangesAsync();
}

// 1. Unconfirmed recipient: no durable intent and no provider call.
var unconfirmed = new RecipientSnapshot("unconfirmed@example.test", false, true);
var unconfirmedIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), unconfirmed);
Require(unconfirmedIntent is null && provider.Calls.Count == 0, "Unconfirmed email must not create/send external delivery.");
scenarios.Add(new { id = "unconfirmed-no-call", passed = true });

// 2. Confirmed identity without product email opt-in: no intent/call.
var noOptIn = new RecipientSnapshot("confirmed@example.test", true, false);
var noOptInIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), noOptIn);
Require(noOptInIntent is null && provider.Calls.Count == 0, "Confirmed email without product opt-in must not create/send.");
scenarios.Add(new { id = "no-product-opt-in-no-call", passed = true });

// 3-4. Eligible source event creates one intent; exact replay converges to same logical intent.
var eligible = new RecipientSnapshot("first@example.test", true, true);
var matchReplay = Guid.NewGuid();
var replayUser = Guid.NewGuid();
var first = await EnsureIntentAsync(matchReplay, replayUser, eligible) ?? throw new InvalidOperationException();
var replay = await EnsureIntentAsync(matchReplay, replayUser, eligible) ?? throw new InvalidOperationException();
Require(first.Id == replay.Id, "Source-event replay must return the same logical intent.");
await using (var db = new MarketplaceDbContext(options))
{
    Require(await db.SavedSearchAlertDeliveryIntents.CountAsync(x => x.SavedSearchAlertMatchId == matchReplay && x.Channel == "email") == 1,
        "Source-event replay must leave exactly one durable intent.");
}
Require(!typeof(SavedSearchAlertDeliveryIntent).GetProperties().Any(x => x.Name.Contains("Email", StringComparison.OrdinalIgnoreCase)),
    "Durable Marketplace intent must not persist recipient email address.");
scenarios.Add(new { id = "durable-intent-and-source-replay", passed = true, intentId = first.Id, idempotencyKey = first.IdempotencyKey });

// 5. Crash after durable intent commit but before provider call: retry sends once.
var preCallCrash = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var callsBefore = provider.Calls.Count;
await DispatchAsync(preCallCrash.Id, eligible, FakeOutcome.Accepted);
Require(provider.Calls.Count == callsBefore + 1 && (await LoadAsync(preCallCrash.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "Pre-call crash recovery must send exactly once when dispatch later executes.");
scenarios.Add(new { id = "crash-before-provider-call", passed = true });

// 6. Timeout with unknown provider outcome remains explicitly ambiguous/recoverable.
var unknown = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(unknown.Id, eligible, FakeOutcome.TimeoutUnknown);
Require((await LoadAsync(unknown.Id)).Status == SavedSearchAlertDeliveryStatus.OutcomeUnknown,
    "Unknown provider outcome must not be labelled accepted or failed.");
scenarios.Add(new { id = "timeout-outcome-unknown", passed = true });

// 7. Provider accepts then process crashes before durable acknowledgement. Same key is retried and provider deduplicates logical acceptance.
var acceptedCrash = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
provider.Send(eligible.Email, acceptedCrash.IdempotencyKey, FakeOutcome.Accepted); // accepted externally; simulate crash before DB update
var logicalBeforeRetry = provider.LogicalAcceptances;
await DispatchAsync(acceptedCrash.Id, eligible, FakeOutcome.Accepted);
Require(provider.LogicalAcceptances == logicalBeforeRetry, "Retry with same idempotency key must not create a second logical provider acceptance.");
Require((await LoadAsync(acceptedCrash.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "Accepted-crash replay must converge durable state to Accepted.");
scenarios.Add(new { id = "accepted-crash-idempotent-retry", passed = true, key = acceptedCrash.IdempotencyKey });

// 8. Opt-out after intent creation but before provider call suppresses the pending intent.
var optOutIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
callsBefore = provider.Calls.Count;
await DispatchAsync(optOutIntent.Id, eligible with { ExternalEmailOptIn = false }, FakeOutcome.Accepted);
Require(provider.Calls.Count == callsBefore && (await LoadAsync(optOutIntent.Id)).Status == SavedSearchAlertDeliveryStatus.Suppressed,
    "Dispatch must revalidate opt-in and suppress without provider call.");
scenarios.Add(new { id = "opt-out-before-call", passed = true });

// 9. Recipient address changes after intent creation: only the current address is used at dispatch.
var changedRecipientIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var changed = eligible with { Email = "current@example.test" };
await DispatchAsync(changedRecipientIntent.Id, changed, FakeOutcome.Accepted);
var changedCall = provider.Calls.Last(x => x.IdempotencyKey == changedRecipientIntent.IdempotencyKey);
Require(changedCall.Email == "current@example.test" && changedCall.Email != eligible.Email,
    "Dispatch must use current recipient authority, not a stale copied address.");
scenarios.Add(new { id = "recipient-change-before-call", passed = true, recipient = changedCall.Email });

// 10. Permanent rejection and transient failure remain distinct states.
var permanent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var transient = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(permanent.Id, eligible, FakeOutcome.PermanentRejected);
await DispatchAsync(transient.Id, eligible, FakeOutcome.TransientFailed);
Require((await LoadAsync(permanent.Id)).Status == SavedSearchAlertDeliveryStatus.PermanentFailed, "Permanent rejection must be terminal/distinct.");
Require((await LoadAsync(transient.Id)).Status == SavedSearchAlertDeliveryStatus.Pending, "Transient failure must remain recoverable/pending.");
scenarios.Add(new { id = "permanent-vs-transient", passed = true });

// 11. Provider delivery callback replay is state-idempotent.
await using (var db = new MarketplaceDbContext(options))
{
    var intent = await db.SavedSearchAlertDeliveryIntents.SingleAsync(x => x.Id == changedRecipientIntent.Id);
    intent.MarkDelivered();
    await db.SaveChangesAsync();
}
await using (var db = new MarketplaceDbContext(options))
{
    var intent = await db.SavedSearchAlertDeliveryIntents.SingleAsync(x => x.Id == changedRecipientIntent.Id);
    intent.MarkDelivered();
    await db.SaveChangesAsync();
}
Require((await LoadAsync(changedRecipientIntent.Id)).Status == SavedSearchAlertDeliveryStatus.Delivered,
    "Replay of the same delivery callback must converge to Delivered.");
scenarios.Add(new { id = "delivery-callback-replay", passed = true });

// 12. One failed intent does not block independent delivery progress.
var independentFail = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var independentOk = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(independentFail.Id, eligible, FakeOutcome.PermanentRejected);
await DispatchAsync(independentOk.Id, eligible, FakeOutcome.Accepted);
Require((await LoadAsync(independentFail.Id)).Status == SavedSearchAlertDeliveryStatus.PermanentFailed &&
        (await LoadAsync(independentOk.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "Failure of one intent must not block independent intent progress.");
scenarios.Add(new { id = "failure-isolation", passed = true });

var artifact = new
{
    schema = "bpt2.saved-search-email-delivery-baseline.v1",
    sourceBoundary = "SavedSearchAlertMatch + UserId + email channel; recipient resolved at dispatch",
    durableIntentStoresRecipientAddress = false,
    productMonitoringOptInIsExternalEmailOptIn = false,
    provider = "provider-neutral fake with idempotency simulation",
    scenarioCount = scenarios.Count,
    scenarios,
    providerCalls = provider.Calls.Count,
    logicalProviderAcceptances = provider.LogicalAcceptances,
    decisions = new
    {
        durableIntentRecovery = "PROVED_BOUNDED",
        sourceReplayIdempotency = "PROVED_BOUNDED",
        recipientRevalidation = "PROVED_BOUNDED",
        providerOutcomeUnknown = "PRESERVED_EXPLICITLY",
        productionProvider = "NOT_SELECTED",
        productionCadence = "UNSET",
        productionConsentSource = "STILL_REQUIRED",
        realEmailSending = "NOT_AUTHORIZED_BY_THIS_BENCHMARK"
    }
};

Directory.CreateDirectory(Path.GetDirectoryName(outputPath) ?? ".");
await File.WriteAllTextAsync(outputPath, JsonSerializer.Serialize(artifact, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine($"SAVED_SEARCH_EMAIL_DELIVERY_SCENARIOS={scenarios.Count}");
Console.WriteLine($"SAVED_SEARCH_EMAIL_DELIVERY_PROVIDER_CALLS={provider.Calls.Count}");
Console.WriteLine($"SAVED_SEARCH_EMAIL_DELIVERY_LOGICAL_ACCEPTANCES={provider.LogicalAcceptances}");
Console.WriteLine("SAVED_SEARCH_EMAIL_DELIVERY_BASELINE=PASS");
Console.WriteLine($"SAVED_SEARCH_EMAIL_DELIVERY_ARTIFACT={outputPath}");

internal sealed record RecipientSnapshot(string Email, bool EmailConfirmed, bool ExternalEmailOptIn);
internal sealed record ProviderCall(string Email, string IdempotencyKey, FakeOutcome RequestedOutcome, bool Deduplicated);
internal enum FakeOutcome { Accepted, TimeoutUnknown, PermanentRejected, TransientFailed }

internal sealed class FakeProvider
{
    private readonly HashSet<string> _acceptedKeys = new(StringComparer.Ordinal);
    public List<ProviderCall> Calls { get; } = [];
    public int LogicalAcceptances => _acceptedKeys.Count;

    public FakeOutcome Send(string email, string idempotencyKey, FakeOutcome requestedOutcome)
    {
        if (_acceptedKeys.Contains(idempotencyKey))
        {
            Calls.Add(new ProviderCall(email, idempotencyKey, requestedOutcome, true));
            return FakeOutcome.Accepted;
        }

        Calls.Add(new ProviderCall(email, idempotencyKey, requestedOutcome, false));
        if (requestedOutcome == FakeOutcome.Accepted)
        {
            _acceptedKeys.Add(idempotencyKey);
        }
        return requestedOutcome;
    }
}
