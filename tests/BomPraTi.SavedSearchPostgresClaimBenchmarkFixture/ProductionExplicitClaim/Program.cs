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
var publicQuery = new BlockingPublicListingQuery(listingId, enteredPublicQuery, releasePublicQuery);

await using var serviceDb = new MarketplaceDbContext(options);
var service = new SavedSearchAlertDetectionAppService(serviceDb, publicQuery);
var evaluation = service.EvaluateAsync(listingId);
await enteredPublicQuery.Task.WaitAsync(TimeSpan.FromSeconds(10));

var lockHeld = await ExactRequestLockIsHeldAsync(options, listingId);
Require(lockHeld, "production EvaluateAsync must hold the exact request row lock while detection is in progress");

releasePublicQuery.SetResult();
var added = await evaluation;
Require(added == 0, "fixture has no Saved Searches, so detection must add zero matches");
Require(publicQuery.GetCalls == 1, "the owner must perform the public Listing lookup exactly once");

await using (var verify = new MarketplaceDbContext(options))
{
    var request = await verify.SavedSearchAlertDetectionRequests
        .AsNoTracking()
        .SingleAsync(x => x.ListingId == listingId);
    Require(request.ProcessedAtUtc.HasValue, "successful owner must mark the request processed");
}

await using (var replayDb = new MarketplaceDbContext(options))
{
    var replayService = new SavedSearchAlertDetectionAppService(replayDb, publicQuery);
    var replayAdded = await replayService.EvaluateAsync(listingId);
    Require(replayAdded == 0, "processed request replay must remain a no-op");
}
Require(publicQuery.GetCalls == 1, "processed replay must return before repeating Listing evaluation");

await using (var afterCommitDb = new MarketplaceDbContext(options))
await using (var transaction = await afterCommitDb.Database.BeginTransactionAsync())
{
    var unlocked = await afterCommitDb.SavedSearchAlertDetectionRequests
        .FromSqlInterpolated($"""
            SELECT *
            FROM "MarketplaceSavedSearchAlertDetectionRequests"
            WHERE "ListingId" = {listingId}
            FOR UPDATE NOWAIT
            """)
        .AsNoTracking()
        .SingleAsync();
    Require(unlocked.Id == requestId, "row must be lockable again after owner commit");
    await transaction.RollbackAsync();
}

Console.WriteLine("SAVED_SEARCH_EXPLICIT_PRODUCTION_LOCK: PASS");
Console.WriteLine("SAVED_SEARCH_EXPLICIT_PROCESSED_REPLAY: PASS");

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

sealed class BlockingPublicListingQuery : IPublicListingQuery
{
    private readonly Guid _listingId;
    private readonly TaskCompletionSource _entered;
    private readonly TaskCompletionSource _release;
    private int _getCalls;

    public BlockingPublicListingQuery(
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
        return new PublicListingDto(
            listingId,
            Guid.Empty,
            null!,
            null!,
            "fixture",
            1m,
            string.Empty,
            null,
            null,
            null,
            "São Paulo",
            "SP",
            Array.Empty<PublicListingPhotoDto>());
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
