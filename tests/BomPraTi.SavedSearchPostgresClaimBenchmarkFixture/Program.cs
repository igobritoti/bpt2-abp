using System.Data;
using System.Diagnostics;
using System.Text.Json;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION")
    ?? throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
var outputPath = Environment.GetEnvironmentVariable("BPT_SAVED_SEARCH_CLAIM_OUTPUT")
    ?? "artifacts/saved-search-postgres-claim-baseline.json";

var options = new DbContextOptionsBuilder<MarketplaceDbContext>()
    .UseNpgsql(connectionString)
    .Options;

var listingA = Guid.Parse("41000000-0000-0000-0000-000000000001");
var listingB = Guid.Parse("41000000-0000-0000-0000-000000000002");
var listingC = Guid.Parse("41000000-0000-0000-0000-000000000003");
var listingD = Guid.Parse("41000000-0000-0000-0000-000000000004");
var listingE = Guid.Parse("41000000-0000-0000-0000-000000000005");
var duplicateListing = Guid.Parse("41000000-0000-0000-0000-000000000099");
var savedSearchId = Guid.Parse("42000000-0000-0000-0000-000000000001");
var baseTime = new DateTime(2026, 8, 29, 12, 0, 0, DateTimeKind.Utc);

await SeedRequestsAsync(options, new[]
{
    (Guid.Parse("40000000-0000-0000-0000-000000000001"), listingA, baseTime.AddSeconds(1)),
    (Guid.Parse("40000000-0000-0000-0000-000000000002"), listingB, baseTime.AddSeconds(2)),
    (Guid.Parse("40000000-0000-0000-0000-000000000003"), listingC, baseTime.AddSeconds(3)),
    (Guid.Parse("40000000-0000-0000-0000-000000000004"), listingD, baseTime.AddSeconds(4)),
    (Guid.Parse("40000000-0000-0000-0000-000000000005"), listingE, baseTime.AddSeconds(5))
});

var observations = new List<object>();

await using var w1 = await ClaimAsync(options, "W1");
Require(w1.Request?.ListingId == listingA, "W1 must claim oldest request A");
await using var w2 = await ClaimAsync(options, "W2");
Require(w2.Request?.ListingId == listingB, "W2 must skip locked A and claim B");
Require(w1.Request!.Id != w2.Request!.Id, "concurrent owners must have disjoint request ids");
observations.Add(new { test = "overlapping-workers", w1 = w1.Request.Id, w2 = w2.Request.Id, disjoint = true, w1.ClaimMs, w2.ClaimMs });

await w1.RollbackAsync();
await using var recoveryA = await ClaimAsync(options, "W3-recovery-A");
Require(recoveryA.Request?.ListingId == listingA, "rolled-back A must become eligible again");
recoveryA.Request.MarkProcessed(baseTime.AddMinutes(1));
await recoveryA.Context.SaveChangesAsync();
await recoveryA.CommitAsync();
observations.Add(new { test = "rollback-recovery", listingId = listingA, recovered = true, recoveryA.ClaimMs, recoveryA.TransactionMs });

w2.Request.MarkProcessed(baseTime.AddMinutes(2));
await w2.Context.SaveChangesAsync();
await w2.CommitAsync();

await using var crashAfterLedger = await ClaimAsync(options, "W4-crash-after-ledger");
Require(crashAfterLedger.Request?.ListingId == listingC, "next pending request must be C");
var insertedFirstMatch = await EnsureMatchAsync(options, savedSearchId, listingC, baseTime.AddMinutes(3));
Require(insertedFirstMatch, "first durable match write must insert");
await crashAfterLedger.RollbackAsync();

await using var replayC = await ClaimAsync(options, "W5-replay-C");
Require(replayC.Request?.ListingId == listingC, "C must be recoverable after owner rollback");
var insertedReplayMatch = await EnsureMatchAsync(options, savedSearchId, listingC, baseTime.AddMinutes(4));
Require(!insertedReplayMatch, "replay must observe durable ledger outcome instead of inserting duplicate");
replayC.Request.MarkProcessed(baseTime.AddMinutes(4));
await replayC.Context.SaveChangesAsync();
await replayC.CommitAsync();
await using (var verify = NewContext(options))
{
    var count = await verify.SavedSearchAlertMatches.CountAsync(x => x.SavedSearchId == savedSearchId && x.ListingId == listingC);
    Require(count == 1, "replay must converge to one durable Saved Search / Listing match");
}
observations.Add(new { test = "crash-after-ledger-replay", listingId = listingC, durableMatches = 1, duplicateInsertAttempted = false });

await using var slowD = await ClaimAsync(options, "W6-slow-D");
Require(slowD.Request?.ListingId == listingD, "slow owner must claim D");
await using var independentE = await ClaimAsync(options, "W7-independent-E");
Require(independentE.Request?.ListingId == listingE, "locked/slow D must not prevent E from progressing");
independentE.Request.MarkProcessed(baseTime.AddMinutes(5));
await independentE.Context.SaveChangesAsync();
await independentE.CommitAsync();
await slowD.RollbackAsync();

await using var restartD = await ClaimAsync(options, "W8-restart-D");
Require(restartD.Request?.ListingId == listingD, "cancelled D must become eligible after restart-equivalent rollback");
restartD.Request.MarkProcessed(baseTime.AddMinutes(6));
await restartD.Context.SaveChangesAsync();
await restartD.CommitAsync();
observations.Add(new { test = "independent-progress-and-cancellation", slow = listingD, progressed = listingE, recovered = listingD });

await using var noMore = await ClaimAsync(options, "W9-after-complete");
Require(noMore.Request is null, "completed requests must not be claimed again");
await noMore.RollbackAsync();
observations.Add(new { test = "completed-noop", eligible = 0 });

var enqueueOutcomes = await RunConcurrentEnqueueRaceAsync(options, duplicateListing, baseTime.AddMinutes(7));
await using (var verify = NewContext(options))
{
    var durable = await verify.SavedSearchAlertDetectionRequests.CountAsync(x => x.ListingId == duplicateListing);
    Require(durable == 1, "concurrent enqueue must converge to one durable request row");
}
Require(enqueueOutcomes.Count(x => x == "INSERTED") == 1, "exactly one enqueue insertion should commit");
Require(enqueueOutcomes.Count(x => x == "UNIQUE_BACKSTOP") == 1, "the competing direct baseline insertion should hit uniqueness backstop");
observations.Add(new { test = "concurrent-enqueue-baseline", outcomes = enqueueOutcomes, durableRows = 1, interpretation = "uniqueness is a backstop, not worker coordination" });

var report = new
{
    schema = "bpt2.saved-search-postgres-claim-baseline.v1",
    protocol = new
    {
        database = "PostgreSQL",
        claim = "SELECT pending request FOR UPDATE SKIP LOCKED LIMIT 1 inside short transaction",
        claimStateColumnsAdded = false,
        schedulingEnabled = false,
        automaticRunnerEnabled = false,
        correctnessStateInProcessMemory = false
    },
    invariants = new
    {
        simultaneousOwnersDisjoint = true,
        rollbackMakesRequestEligible = true,
        crashAfterLedgerReplayIdempotent = true,
        completedNeverReclaimed = true,
        slowLockedItemDoesNotBlockIndependentItem = true,
        cancellationEquivalentRollbackRecoverable = true,
        concurrentEnqueueOneDurableRow = true,
        uniquenessUsedAsWorkerCoordination = false
    },
    observations,
    disposition = new
    {
        postgresTransactionalClaim = "BASELINE_PROVED_BOUNDED",
        productionRunner = "NOT_YET_SELECTED",
        transactionAcrossFullDetection = "NOT_AUTHORIZED_BY_THIS_BENCHMARK",
        durableClaimColumns = "NOT_JUSTIFIED_YET",
        abpBackgroundJobs = "COMPARATOR_IF_RETRY_SCHEDULING_COMPLEXITY_JUSTIFIES",
        hangfireQuartzRedis = "NOT_JUSTIFIED",
        pollLeaseRetryThresholds = "UNSET"
    }
};
Directory.CreateDirectory(Path.GetDirectoryName(outputPath) ?? ".");
await File.WriteAllTextAsync(outputPath, JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine("SAVED_SEARCH_POSTGRES_CLAIM_OVERLAP: PASS");
Console.WriteLine("SAVED_SEARCH_POSTGRES_CLAIM_ROLLBACK_RECOVERY: PASS");
Console.WriteLine("SAVED_SEARCH_POSTGRES_CLAIM_LEDGER_REPLAY: PASS");
Console.WriteLine("SAVED_SEARCH_POSTGRES_CLAIM_INDEPENDENT_PROGRESS: PASS");
Console.WriteLine("SAVED_SEARCH_POSTGRES_CLAIM_COMPLETED_NOOP: PASS");
Console.WriteLine("SAVED_SEARCH_CONCURRENT_ENQUEUE_BACKSTOP: PASS");
Console.WriteLine($"SAVED_SEARCH_POSTGRES_CLAIM_ARTIFACT: {outputPath}");

static MarketplaceDbContext NewContext(DbContextOptions<MarketplaceDbContext> options) => new(options);

static async Task SeedRequestsAsync(
    DbContextOptions<MarketplaceDbContext> options,
    IEnumerable<(Guid Id, Guid ListingId, DateTime EnqueuedAtUtc)> requests)
{
    await using var db = NewContext(options);
    foreach (var request in requests)
    {
        db.SavedSearchAlertDetectionRequests.Add(new SavedSearchAlertDetectionRequest(request.Id, request.ListingId, request.EnqueuedAtUtc));
    }
    await db.SaveChangesAsync();
}

static async Task<ClaimHandle> ClaimAsync(DbContextOptions<MarketplaceDbContext> options, string worker)
{
    var context = NewContext(options);
    var transactionWatch = Stopwatch.StartNew();
    var transaction = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
    var claimWatch = Stopwatch.StartNew();
    var request = await context.SavedSearchAlertDetectionRequests
        .FromSqlRaw("""
            SELECT *
            FROM "MarketplaceSavedSearchAlertDetectionRequests"
            WHERE "ProcessedAtUtc" IS NULL
            ORDER BY "EnqueuedAtUtc", "Id"
            FOR UPDATE SKIP LOCKED
            LIMIT 1
            """)
        .AsTracking()
        .SingleOrDefaultAsync();
    claimWatch.Stop();
    return new ClaimHandle(worker, context, transaction, request, claimWatch.Elapsed.TotalMilliseconds, transactionWatch);
}

static async Task<bool> EnsureMatchAsync(
    DbContextOptions<MarketplaceDbContext> options,
    Guid savedSearchId,
    Guid listingId,
    DateTime detectedAtUtc)
{
    await using var db = NewContext(options);
    if (await db.SavedSearchAlertMatches.AnyAsync(x => x.SavedSearchId == savedSearchId && x.ListingId == listingId)) return false;
    db.SavedSearchAlertMatches.Add(new SavedSearchAlertMatch(Guid.NewGuid(), savedSearchId, listingId, detectedAtUtc));
    await db.SaveChangesAsync();
    return true;
}

static async Task<string[]> RunConcurrentEnqueueRaceAsync(
    DbContextOptions<MarketplaceDbContext> options,
    Guid listingId,
    DateTime enqueuedAtUtc)
{
    var gate = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
    async Task<string> Insert(Guid id)
    {
        await gate.Task;
        await using var db = NewContext(options);
        db.SavedSearchAlertDetectionRequests.Add(new SavedSearchAlertDetectionRequest(id, listingId, enqueuedAtUtc));
        try
        {
            await db.SaveChangesAsync();
            return "INSERTED";
        }
        catch (DbUpdateException)
        {
            return "UNIQUE_BACKSTOP";
        }
    }
    var a = Insert(Guid.Parse("40000000-0000-0000-0000-000000000098"));
    var b = Insert(Guid.Parse("40000000-0000-0000-0000-000000000099"));
    gate.SetResult();
    return await Task.WhenAll(a, b);
}

static void Require(bool condition, string message)
{
    if (!condition) throw new InvalidOperationException(message);
}

sealed class ClaimHandle : IAsyncDisposable
{
    private readonly Stopwatch _transactionWatch;
    private bool _finished;

    public ClaimHandle(
        string worker,
        MarketplaceDbContext context,
        IDbContextTransaction transaction,
        SavedSearchAlertDetectionRequest? request,
        double claimMs,
        Stopwatch transactionWatch)
    {
        Worker = worker;
        Context = context;
        Transaction = transaction;
        Request = request;
        ClaimMs = claimMs;
        _transactionWatch = transactionWatch;
    }

    public string Worker { get; }
    public MarketplaceDbContext Context { get; }
    public IDbContextTransaction Transaction { get; }
    public SavedSearchAlertDetectionRequest? Request { get; }
    public double ClaimMs { get; }
    public double TransactionMs => _transactionWatch.Elapsed.TotalMilliseconds;

    public async Task CommitAsync()
    {
        if (_finished) return;
        await Transaction.CommitAsync();
        _transactionWatch.Stop();
        _finished = true;
    }

    public async Task RollbackAsync()
    {
        if (_finished) return;
        await Transaction.RollbackAsync();
        _transactionWatch.Stop();
        _finished = true;
    }

    public async ValueTask DisposeAsync()
    {
        if (!_finished) await Transaction.RollbackAsync();
        _transactionWatch.Stop();
        await Transaction.DisposeAsync();
        await Context.DisposeAsync();
        _finished = true;
    }
}
