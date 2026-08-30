using System.Text.Json;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;

var connection = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION")
    ?? throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
var outputPath = Environment.GetEnvironmentVariable("BPT_SAVED_SEARCH_EMAIL_DELIVERY_OUTPUT")
    ?? "artifacts/saved-search-email-delivery-baseline.json";
var options = new DbContextOptionsBuilder<MarketplaceDbContext>().UseNpgsql(connection).Options;
var now = new DateTime(2026, 8, 29, 18, 0, 0, DateTimeKind.Utc);
var provider = new FakeProvider();
var scenarios = new List<object>();

static MarketplaceDbContext NewContext(DbContextOptions<MarketplaceDbContext> options) => new(options);
static void Require(bool condition, string message)
{
    if (!condition) throw new InvalidOperationException(message);
}

async Task<SavedSearchAlertDeliveryIntent?> EnsureIntentAsync(Guid matchId, Guid userId, RecipientSnapshot recipient)
{
    if (!recipient.EmailConfirmed || !recipient.ExternalEmailOptIn) return null;
    await using var db = NewContext(options);
    var existing = await db.SavedSearchAlertDeliveryIntents.AsNoTracking()
        .SingleOrDefaultAsync(x => x.SavedSearchAlertMatchId == matchId && x.Channel == "email");
    if (existing is not null) return existing;

    var intent = new SavedSearchAlertDeliveryIntent(Guid.NewGuid(), matchId, userId, "email", now);
    await db.Database.ExecuteSqlInterpolatedAsync($"""
        INSERT INTO "MarketplaceSavedSearchAlertDeliveryIntents"
            ("Id", "SavedSearchAlertMatchId", "UserId", "Channel", "IdempotencyKey", "Status", "CreatedAtUtc", "LastAttemptAtUtc")
        VALUES
            ({intent.Id}, {intent.SavedSearchAlertMatchId}, {intent.UserId}, {intent.Channel}, {intent.IdempotencyKey}, {intent.Status.ToString()}, {intent.CreatedAtUtc}, NULL)
        ON CONFLICT ("SavedSearchAlertMatchId", "Channel") DO NOTHING
        """);
    return await db.SavedSearchAlertDeliveryIntents.AsNoTracking()
        .SingleAsync(x => x.SavedSearchAlertMatchId == matchId && x.Channel == "email");
}

async Task<SavedSearchAlertDeliveryIntent> LoadAsync(Guid id)
{
    await using var db = NewContext(options);
    return await db.SavedSearchAlertDeliveryIntents.AsNoTracking().SingleAsync(x => x.Id == id);
}

async Task SetStatusAsync(Guid id, SavedSearchAlertDeliveryStatus status, DateTime? attemptedAtUtc)
{
    var normalizedAttemptedAtUtc = attemptedAtUtc is null
        ? (DateTime?)null
        : DateTime.SpecifyKind(attemptedAtUtc.Value, DateTimeKind.Utc);
    await using var db = NewContext(options);
    await db.Database.ExecuteSqlInterpolatedAsync($"""
        UPDATE "MarketplaceSavedSearchAlertDeliveryIntents"
        SET "Status" = {status.ToString()}, "LastAttemptAtUtc" = {normalizedAttemptedAtUtc}
        WHERE "Id" = {id}
        """);
}

async Task DispatchAsync(Guid intentId, RecipientSnapshot recipient, FakeOutcome outcome)
{
    var intent = await LoadAsync(intentId);
    if (!recipient.EmailConfirmed || !recipient.ExternalEmailOptIn)
    {
        await SetStatusAsync(intent.Id, SavedSearchAlertDeliveryStatus.Suppressed, intent.LastAttemptAtUtc);
        return;
    }

    var result = provider.Send(recipient.Email, intent.IdempotencyKey, outcome);
    var status = result switch
    {
        FakeOutcome.Accepted => SavedSearchAlertDeliveryStatus.Accepted,
        FakeOutcome.TimeoutUnknown => SavedSearchAlertDeliveryStatus.OutcomeUnknown,
        FakeOutcome.PermanentRejected => SavedSearchAlertDeliveryStatus.PermanentFailed,
        FakeOutcome.TransientFailed => SavedSearchAlertDeliveryStatus.Pending,
        _ => throw new ArgumentOutOfRangeException(nameof(outcome))
    };
    await SetStatusAsync(intent.Id, status, now.AddMinutes(1));
}

var unconfirmed = new RecipientSnapshot("unconfirmed@example.test", false, true);
Require(await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), unconfirmed) is null && provider.Calls.Count == 0,
    "Unconfirmed email must not create/send external delivery.");
scenarios.Add(new { id = "unconfirmed-no-call", passed = true });

var noOptIn = new RecipientSnapshot("confirmed@example.test", true, false);
Require(await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), noOptIn) is null && provider.Calls.Count == 0,
    "Confirmed email without product opt-in must not create/send.");
scenarios.Add(new { id = "no-product-opt-in-no-call", passed = true });

var eligible = new RecipientSnapshot("first@example.test", true, true);
var replayMatch = Guid.NewGuid();
var replayUser = Guid.NewGuid();
var first = await EnsureIntentAsync(replayMatch, replayUser, eligible) ?? throw new InvalidOperationException();
var replay = await EnsureIntentAsync(replayMatch, replayUser, eligible) ?? throw new InvalidOperationException();
Require(first.Id == replay.Id, "Source-event replay must converge to same logical intent.");
await using (var db = NewContext(options))
{
    Require(await db.SavedSearchAlertDeliveryIntents.AsNoTracking().CountAsync(x => x.SavedSearchAlertMatchId == replayMatch && x.Channel == "email") == 1,
        "Source replay must leave exactly one intent.");
}
Require(!typeof(SavedSearchAlertDeliveryIntent).GetProperties().Any(x => x.Name.Contains("Email", StringComparison.OrdinalIgnoreCase)),
    "Durable Marketplace intent must not persist recipient email address.");
scenarios.Add(new { id = "durable-intent-and-source-replay", passed = true, intentId = first.Id, first.IdempotencyKey });

var preCallCrash = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var callsBefore = provider.Calls.Count;
await DispatchAsync(preCallCrash.Id, eligible, FakeOutcome.Accepted);
Require(provider.Calls.Count == callsBefore + 1 && (await LoadAsync(preCallCrash.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "Pre-call crash recovery must later send exactly once.");
scenarios.Add(new { id = "crash-before-provider-call", passed = true });

var unknown = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(unknown.Id, eligible, FakeOutcome.TimeoutUnknown);
Require((await LoadAsync(unknown.Id)).Status == SavedSearchAlertDeliveryStatus.OutcomeUnknown,
    "Unknown provider outcome must remain explicit.");
scenarios.Add(new { id = "timeout-outcome-unknown", passed = true });

var acceptedCrash = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
provider.Send(eligible.Email, acceptedCrash.IdempotencyKey, FakeOutcome.Accepted);
var logicalBeforeRetry = provider.LogicalAcceptances;
await DispatchAsync(acceptedCrash.Id, eligible, FakeOutcome.Accepted);
Require(provider.LogicalAcceptances == logicalBeforeRetry && (await LoadAsync(acceptedCrash.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "Accepted-crash retry must reuse key and converge without duplicate logical acceptance.");
scenarios.Add(new { id = "accepted-crash-idempotent-retry", passed = true, key = acceptedCrash.IdempotencyKey });

var optOutIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
callsBefore = provider.Calls.Count;
await DispatchAsync(optOutIntent.Id, eligible with { ExternalEmailOptIn = false }, FakeOutcome.Accepted);
Require(provider.Calls.Count == callsBefore && (await LoadAsync(optOutIntent.Id)).Status == SavedSearchAlertDeliveryStatus.Suppressed,
    "Opt-out before call must suppress without provider call.");
scenarios.Add(new { id = "opt-out-before-call", passed = true });

var changedIntent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var changed = eligible with { Email = "current@example.test" };
await DispatchAsync(changedIntent.Id, changed, FakeOutcome.Accepted);
var changedCall = provider.Calls.Last(x => x.IdempotencyKey == changedIntent.IdempotencyKey);
Require(changedCall.Email == changed.Email && changedCall.Email != eligible.Email,
    "Dispatch must resolve current recipient, not stale address.");
scenarios.Add(new { id = "recipient-change-before-call", passed = true, recipient = changedCall.Email });

var permanent = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var transient = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(permanent.Id, eligible, FakeOutcome.PermanentRejected);
await DispatchAsync(transient.Id, eligible, FakeOutcome.TransientFailed);
Require((await LoadAsync(permanent.Id)).Status == SavedSearchAlertDeliveryStatus.PermanentFailed,
    "Permanent rejection must be terminal/distinct.");
Require((await LoadAsync(transient.Id)).Status == SavedSearchAlertDeliveryStatus.Pending,
    "Transient failure must remain recoverable.");
scenarios.Add(new { id = "permanent-vs-transient", passed = true });

await SetStatusAsync(changedIntent.Id, SavedSearchAlertDeliveryStatus.Delivered, (await LoadAsync(changedIntent.Id)).LastAttemptAtUtc);
await SetStatusAsync(changedIntent.Id, SavedSearchAlertDeliveryStatus.Delivered, (await LoadAsync(changedIntent.Id)).LastAttemptAtUtc);
Require((await LoadAsync(changedIntent.Id)).Status == SavedSearchAlertDeliveryStatus.Delivered,
    "Callback replay must converge idempotently to Delivered.");
scenarios.Add(new { id = "delivery-callback-replay", passed = true });

var isolatedFail = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
var isolatedOk = await EnsureIntentAsync(Guid.NewGuid(), Guid.NewGuid(), eligible) ?? throw new InvalidOperationException();
await DispatchAsync(isolatedFail.Id, eligible, FakeOutcome.PermanentRejected);
await DispatchAsync(isolatedOk.Id, eligible, FakeOutcome.Accepted);
Require((await LoadAsync(isolatedFail.Id)).Status == SavedSearchAlertDeliveryStatus.PermanentFailed &&
        (await LoadAsync(isolatedOk.Id)).Status == SavedSearchAlertDeliveryStatus.Accepted,
    "One failed intent must not block independent progress.");
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
        if (requestedOutcome == FakeOutcome.Accepted) _acceptedKeys.Add(idempotencyKey);
        return requestedOutcome;
    }
}
