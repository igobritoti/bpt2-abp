using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Npgsql;
using Volo.Abp.Application.Dtos;

var connectionString = Environment.GetEnvironmentVariable("BPT_DB_CONNECTION")
    ?? throw new InvalidOperationException("BPT_DB_CONNECTION is required.");
var options = new DbContextOptionsBuilder<MarketplaceDbContext>()
    .UseNpgsql(connectionString)
    .Options;
var listingId = Guid.Parse("43000000-0000-0000-0000-000000000001");
var requestId = Guid.Parse("44000000-0000-0000-0000-000000000001");
var enqueuedAtUtc = new DateTime(2026, 8, 30, 1, 0, 0, DateTimeKind.Utc);

await SeedRequestAsync(options, requestId, listingId, enqueuedAtUtc);

var enteredPublicQuery = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
var releasePublicQuery = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
var publicQuery = new BlockingMissingPublicListingQuery(listingId, enteredPublicQuery, releasePublicQuery);

await using var serviceDb = new MarketplaceDbContext(options);
var service = new SavedSearchAlertDetectionProcessor(
    serviceDb,
    publicQuery,
    Options.Create(new SavedSearchAlertRunnerOptions()));
var evaluation = service.EvaluateAsync(listingId);
await enteredPublicQuery.Task.WaitAsync(TimeSpan.FromSeconds(10));

var lockHeld = await ExactRequestLockIsHeldAsync(options, listingId);
Require(lockHeld, "production EvaluateAsync must hold the exact request row lock while Listing evaluation is in progress");

releasePublicQuery.SetResult();
var added = await evaluation;
Require(added == 0, "missing public Listing must remain a zero-match no-op");
Require(publicQuery.GetCalls == 1, "the explicit owner must perform the public Listing lookup exactly once");

await using (var verify = new MarketplaceDbContext(options))
{
    var request = await verify.SavedSearchAlertDetectionRequests
        .AsNoTracking()
        .SingleAsync(x => x.ListingId == listingId);
    Require(!request.ProcessedAtUtc.HasValue, "missing public Listing must preserve the current pending request behavior");
    Require(request.NextAttemptAtUtc.HasValue, "missing public Listing must schedule the next retry");
    var nextAttemptAtUtc = request.NextAttemptAtUtc.GetValueOrDefault();
    Require(nextAttemptAtUtc > enqueuedAtUtc, "retry must be deferred after the original enqueue time");
}

await using (var afterReturnDb = new MarketplaceDbContext(options))
await using (var transaction = await afterReturnDb.Database.BeginTransactionAsync())
{
    var unlocked = await afterReturnDb.SavedSearchAlertDetectionRequests
        .FromSqlInterpolated($"""
            SELECT *
            FROM "MarketplaceSavedSearchAlertDetectionRequests"
            WHERE "ListingId" = {listingId}
            FOR UPDATE NOWAIT
            """)
        .AsNoTracking()
        .SingleAsync();
    Require(unlocked.Id == requestId, "row must be lockable again after the explicit owner returns");
    await transaction.RollbackAsync();
}

Console.WriteLine("SAVED_SEARCH_EXPLICIT_PRODUCTION_LOCK_HELD: PASS");
Console.WriteLine("SAVED_SEARCH_EXPLICIT_LOCK_RELEASED_ON_RETURN: PASS");
Console.WriteLine("SAVED_SEARCH_MISSING_LISTING_REMAINS_PENDING: PASS");

var retryDelay = TimeSpan.FromMilliseconds(200);
var failingListingId = Guid.Parse("43000000-0000-0000-0000-000000000002");
var healthyListingId = Guid.Parse("43000000-0000-0000-0000-000000000003");
var cancelledListingId = Guid.Parse("43000000-0000-0000-0000-000000000004");
var failingRequestId = Guid.Parse("44000000-0000-0000-0000-000000000002");
var healthyRequestId = Guid.Parse("44000000-0000-0000-0000-000000000003");
var cancelledRequestId = Guid.Parse("44000000-0000-0000-0000-000000000004");
var retryBaseUtc = enqueuedAtUtc.AddMinutes(5);

await SeedRequestAsync(options, failingRequestId, failingListingId, retryBaseUtc);
await SeedRequestAsync(options, healthyRequestId, healthyListingId, retryBaseUtc.AddSeconds(1));
await SeedRequestAsync(options, cancelledRequestId, cancelledListingId, retryBaseUtc.AddSeconds(2));

var retryingQuery = new RetryingPublicListingQuery(
    failingListingId,
    healthyListingId,
    cancelledListingId);
var retryingOptions = Options.Create(new SavedSearchAlertRunnerOptions
{
    Enabled = true,
    IdleDelay = TimeSpan.FromMilliseconds(10),
    MissingListingRetryDelay = retryDelay
});

await using (var retryDb = new MarketplaceDbContext(options))
{
    var processor = new SavedSearchAlertDetectionProcessor(retryDb, retryingQuery, retryingOptions);
    var failingAttempt = await processor.EvaluateAsync(failingListingId);
    Require(failingAttempt == 0, "generic processing failure must remain a zero-match result");
}

await using (var afterFailureDb = new MarketplaceDbContext(options))
{
    var failingRequest = await afterFailureDb.SavedSearchAlertDetectionRequests
        .AsNoTracking()
        .SingleAsync(x => x.ListingId == failingListingId);
    Require(failingRequest.LastAttemptAtUtc.HasValue, "generic failure must record the real attempt time");
    Require(failingRequest.NextAttemptAtUtc.HasValue, "generic failure must schedule a retry");
    Require(failingRequest.NextAttemptAtUtc.Value > failingRequest.LastAttemptAtUtc.GetValueOrDefault(), "retry must be deferred after the actual attempt");
    var healthyEligible = await SelectNextDueListingIdAsync(options, retryBaseUtc);
    Require(healthyEligible == healthyListingId, "a problematic request must not starve another due request");
}

await using (var healthyDb = new MarketplaceDbContext(options))
{
    var processor = new SavedSearchAlertDetectionProcessor(healthyDb, retryingQuery, retryingOptions);
    var healthyAttempt = await processor.EvaluateAsync(healthyListingId);
    Require(healthyAttempt == 0, "healthy request without matches must remain a zero-match result");
}

await Task.Delay(retryDelay + TimeSpan.FromMilliseconds(150));

await using (var retryEligibleDb = new MarketplaceDbContext(options))
{
    var retryEligibleListing = await SelectNextDueListingIdAsync(options, DateTime.UtcNow);
    Require(retryEligibleListing == failingListingId, "problematic request must become eligible again after the retry delay");
}

await using (var retryAttemptDb = new MarketplaceDbContext(options))
{
    var processor = new SavedSearchAlertDetectionProcessor(retryAttemptDb, retryingQuery, retryingOptions);
    var retriedAttempt = await processor.EvaluateAsync(failingListingId);
    Require(retriedAttempt == 0, "recovered request without matches must remain a zero-match result");
}

await using (var verifyRetryDb = new MarketplaceDbContext(options))
{
    var failingRequest = await verifyRetryDb.SavedSearchAlertDetectionRequests
        .AsNoTracking()
        .SingleAsync(x => x.ListingId == failingListingId);
    Require(failingRequest.ProcessedAtUtc.HasValue, "recovered request must eventually complete");
    Require(!failingRequest.NextAttemptAtUtc.HasValue, "completed request must clear retry metadata");
}

var cancellationQuery = new CancelledPublicListingQuery(cancelledListingId);
await using (var cancellationDb = new MarketplaceDbContext(options))
{
    var processor = new SavedSearchAlertDetectionProcessor(cancellationDb, cancellationQuery, retryingOptions);
    var cancellationTokenSource = new CancellationTokenSource();
    cancellationTokenSource.Cancel();

    try
    {
        await processor.EvaluateAsync(cancelledListingId, cancellationTokenSource.Token);
        throw new InvalidOperationException("cancellation must not be swallowed");
    }
    catch (OperationCanceledException)
    {
    }
}

await using (var verifyCancellationDb = new MarketplaceDbContext(options))
{
    var cancelledRequest = await verifyCancellationDb.SavedSearchAlertDetectionRequests
        .AsNoTracking()
        .SingleAsync(x => x.ListingId == cancelledListingId);
    Require(!cancelledRequest.LastAttemptAtUtc.HasValue, "cancellation must not record a failure attempt");
    Require(!cancelledRequest.NextAttemptAtUtc.HasValue, "cancellation must not schedule a retry");
    Require(!cancelledRequest.ProcessedAtUtc.HasValue, "cancellation must not mark the request processed");
}

Console.WriteLine("SAVED_SEARCH_GENERIC_FAILURE_RETRY: PASS");
Console.WriteLine("SAVED_SEARCH_POISON_REQUEST_NON_STARVATION: PASS");
Console.WriteLine("SAVED_SEARCH_RETRY_ELIGIBILITY_AFTER_DELAY: PASS");
Console.WriteLine("SAVED_SEARCH_CANCELLATION_DOES_NOT_RETRY: PASS");

static async Task SeedRequestAsync(
    DbContextOptions<MarketplaceDbContext> options,
    Guid requestId,
    Guid listingId,
    DateTime enqueuedAtUtc)
{
    await using var db = new MarketplaceDbContext(options);
    var extraProperties = "{}";
    var concurrencyStamp = Guid.NewGuid().ToString("N");
    var affected = await db.Database.ExecuteSqlInterpolatedAsync($"""
        INSERT INTO "MarketplaceSavedSearchAlertDetectionRequests"
            ("Id", "ListingId", "EnqueuedAtUtc", "ProcessedAtUtc", "ExtraProperties", "ConcurrencyStamp")
        VALUES ({requestId}, {listingId}, {enqueuedAtUtc}, NULL, {extraProperties}, {concurrencyStamp})
        """);
    Require(affected == 1, "fixture request insert failed");
}

static async Task<bool> ExactRequestLockIsHeldAsync(
    DbContextOptions<MarketplaceDbContext> options,
    Guid listingId)
{
    await using var db = new MarketplaceDbContext(options);
    await using var transaction = await db.Database.BeginTransactionAsync();
    try
    {
        _ = await db.SavedSearchAlertDetectionRequests
            .FromSqlInterpolated($"""
                SELECT *
                FROM "MarketplaceSavedSearchAlertDetectionRequests"
                WHERE "ListingId" = {listingId}
                FOR UPDATE NOWAIT
                """)
            .AsNoTracking()
            .SingleAsync();
        await transaction.RollbackAsync();
        return false;
    }
    catch (Exception exception) when (FindPostgresException(exception)?.SqlState == PostgresErrorCodes.LockNotAvailable)
    {
        await transaction.RollbackAsync();
        return true;
    }
}

static PostgresException? FindPostgresException(Exception exception)
{
    for (var current = exception; current is not null; current = current.InnerException!)
    {
        if (current is PostgresException postgres)
        {
            return postgres;
        }

        if (current.InnerException is null)
        {
            break;
        }
    }

    return null;
}

static void Require(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}

static async Task<Guid?> SelectNextDueListingIdAsync(
    DbContextOptions<MarketplaceDbContext> options,
    DateTime nowUtc)
{
    await using var db = new MarketplaceDbContext(options);
    await using var transaction = await db.Database.BeginTransactionAsync();
    try
    {
        var request = await db.SavedSearchAlertDetectionRequests
            .FromSqlInterpolated($"""
                SELECT *
                FROM "MarketplaceSavedSearchAlertDetectionRequests"
                WHERE "ProcessedAtUtc" IS NULL
                  AND ("NextAttemptAtUtc" IS NULL OR "NextAttemptAtUtc" <= {nowUtc})
                ORDER BY "EnqueuedAtUtc", "Id"
                LIMIT 1
                FOR UPDATE SKIP LOCKED
                """)
            .AsNoTracking()
            .SingleOrDefaultAsync();

        if (request is null)
        {
            await transaction.RollbackAsync();
            return null;
        }

        await transaction.RollbackAsync();
        return request.ListingId;
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}

sealed class BlockingMissingPublicListingQuery : IPublicListingQuery
{
    private readonly Guid _listingId;
    private readonly TaskCompletionSource _entered;
    private readonly TaskCompletionSource _release;
    private int _getCalls;

    public BlockingMissingPublicListingQuery(
        Guid listingId,
        TaskCompletionSource entered,
        TaskCompletionSource release)
    {
        _listingId = listingId;
        _entered = entered;
        _release = release;
    }

    public int GetCalls => Volatile.Read(ref _getCalls);

    public async Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (listingId != _listingId)
        {
            throw new InvalidOperationException("unexpected Listing id");
        }

        Interlocked.Increment(ref _getCalls);
        _entered.TrySetResult();
        await _release.Task.WaitAsync(cancellationToken);
        return null;
    }

    public Task<IReadOnlyList<PublicListingDto>> GetManyAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        Guid? vehicleId = null,
        string? query = null,
        int skip = 0,
        int take = 20,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<PagedResultDto<PublicListingDto>> SearchPageAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<bool> MatchesAsync(
        Guid listingId,
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();
}

sealed class RetryingPublicListingQuery : IPublicListingQuery
{
    private readonly Guid _failingListingId;
    private readonly Guid _healthyListingId;
    private readonly Guid _cancelledListingId;
    private int _failingGetCalls;

    public RetryingPublicListingQuery(
        Guid failingListingId,
        Guid healthyListingId,
        Guid cancelledListingId)
    {
        _failingListingId = failingListingId;
        _healthyListingId = healthyListingId;
        _cancelledListingId = cancelledListingId;
    }

    public async Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (listingId == _failingListingId)
        {
            var current = Interlocked.Increment(ref _failingGetCalls);
            if (current == 1)
            {
                throw new InvalidOperationException("synthetic generic processing failure");
            }
        }

        if (listingId != _failingListingId
            && listingId != _healthyListingId
            && listingId != _cancelledListingId)
        {
            throw new InvalidOperationException("unexpected Listing id");
        }

        await Task.CompletedTask;
        return CreateListing(listingId);
    }

    public Task<IReadOnlyList<PublicListingDto>> GetManyAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        Guid? vehicleId = null,
        string? query = null,
        int skip = 0,
        int take = 20,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<PagedResultDto<PublicListingDto>> SearchPageAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<bool> MatchesAsync(
        Guid listingId,
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => Task.FromResult(false);

    private static PublicListingDto CreateListing(Guid listingId) => new(
        listingId,
        Guid.Parse("45000000-0000-0000-0000-000000000001"),
        new PublicListingVehicleDto(
            Guid.Parse("46000000-0000-0000-0000-000000000001"),
            "Brand",
            "Model",
            null,
            "Version",
            2026),
        new PublicListingSellerDto(
            Guid.Parse("47000000-0000-0000-0000-000000000001"),
            "Seller",
            null),
        "Title",
        10000m,
        "Description",
        2026,
        0,
        null,
        "City",
        "SP",
        Array.Empty<PublicListingPhotoDto>());
}

sealed class CancelledPublicListingQuery : IPublicListingQuery
{
    private readonly Guid _listingId;

    public CancelledPublicListingQuery(Guid listingId)
    {
        _listingId = listingId;
    }

    public async Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (listingId != _listingId)
        {
            throw new InvalidOperationException("unexpected Listing id");
        }

        await Task.Delay(TimeSpan.FromMinutes(1), cancellationToken);
        return CreateListing(listingId);
    }

    public Task<IReadOnlyList<PublicListingDto>> GetManyAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        Guid? vehicleId = null,
        string? query = null,
        int skip = 0,
        int take = 20,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<PagedResultDto<PublicListingDto>> SearchPageAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    public Task<bool> MatchesAsync(
        Guid listingId,
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) => throw new NotSupportedException();

    private static PublicListingDto CreateListing(Guid listingId) => new(
        listingId,
        Guid.Parse("45000000-0000-0000-0000-000000000002"),
        new PublicListingVehicleDto(
            Guid.Parse("46000000-0000-0000-0000-000000000002"),
            "Brand",
            "Model",
            null,
            "Version",
            2026),
        new PublicListingSellerDto(
            Guid.Parse("47000000-0000-0000-0000-000000000002"),
            "Seller",
            null),
        "Title",
        10000m,
        "Description",
        2026,
        0,
        null,
        "City",
        "SP",
        Array.Empty<PublicListingPhotoDto>());
}
