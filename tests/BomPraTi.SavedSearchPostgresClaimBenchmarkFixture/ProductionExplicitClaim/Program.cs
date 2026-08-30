using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Services;
using Microsoft.EntityFrameworkCore;
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
var service = new SavedSearchAlertDetectionAppService(serviceDb, publicQuery);
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
    Require(request.NextAttemptAtUtc.Value > enqueuedAtUtc, "retry must be deferred after the original enqueue time");
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
