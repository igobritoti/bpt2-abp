using System.Data;
using System.Security.Cryptography;
using System.Text;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchEmailDeliveryProcessor : ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ISavedSearchEmailRecipientResolver _recipientResolver;
    private readonly ISavedSearchEmailTransport _transport;
    private readonly SavedSearchEmailDeliveryOptions _options;

    public SavedSearchEmailDeliveryProcessor(
        MarketplaceDbContext dbContext,
        ISavedSearchEmailRecipientResolver recipientResolver,
        ISavedSearchEmailTransport transport,
        IOptions<SavedSearchEmailDeliveryOptions> options)
    {
        _dbContext = dbContext;
        _recipientResolver = recipientResolver;
        _transport = transport;
        _options = options.Value;
    }

    public async Task<bool> ProcessNextAsync(CancellationToken cancellationToken = default)
    {
        var nowUtc = DateTime.UtcNow;
        SavedSearchAlertDeliveryIntent? intent;

        await using (var claimTransaction = await _dbContext.Database.BeginTransactionAsync(
                         IsolationLevel.ReadCommitted,
                         cancellationToken))
        {
            intent = await _dbContext.SavedSearchAlertDeliveryIntents
                .FromSqlInterpolated($"""
                    SELECT *
                    FROM "MarketplaceSavedSearchAlertDeliveryIntents"
                    WHERE "Channel" = 'email'
                      AND (
                        "Status" = 'Pending'
                        OR ("Status" = 'RetryScheduled' AND "NextAttemptAtUtc" <= {nowUtc})
                        OR ("Status" = 'OutcomeUnknown' AND ("NextAttemptAtUtc" IS NULL OR "NextAttemptAtUtc" <= {nowUtc}))
                        OR ("Status" = 'InFlight' AND "LeaseExpiresAtUtc" <= {nowUtc})
                      )
                    ORDER BY "CreatedAtUtc", "Id"
                    LIMIT 1
                    FOR UPDATE SKIP LOCKED
                    """)
                .SingleOrDefaultAsync(cancellationToken);

            if (intent is null)
            {
                await claimTransaction.RollbackAsync(cancellationToken);
                return false;
            }

            intent.MarkInFlight(nowUtc, nowUtc.Add(_options.LeaseDuration));
            await _dbContext.SaveChangesAsync(cancellationToken);
            await claimTransaction.CommitAsync(cancellationToken);
        }

        var eligibility = await ResolveEligibilityAsync(intent.SavedSearchAlertMatchId, cancellationToken);
        if (eligibility is null)
        {
            await SuppressAsync(intent.Id, cancellationToken);
            return true;
        }

        var recipient = await _recipientResolver.ResolveVerifiedAsync(intent.UserId, cancellationToken);
        if (recipient is null)
        {
            await SuppressAsync(intent.Id, cancellationToken);
            return true;
        }

        if (!await BindRecipientAsync(intent.Id, recipient.Email, cancellationToken))
        {
            await SuppressAsync(intent.Id, cancellationToken);
            return true;
        }

        // Authorization and Saved Search existence are checked again immediately before external I/O.
        eligibility = await ResolveEligibilityAsync(intent.SavedSearchAlertMatchId, cancellationToken);
        if (eligibility is null)
        {
            await SuppressAsync(intent.Id, cancellationToken);
            return true;
        }

        SavedSearchEmailSendResult result;
        try
        {
            result = await _transport.SendAsync(
                new SavedSearchEmailMessage(
                    intent.Id,
                    eligibility.ListingId,
                    eligibility.SavedSearchId,
                    recipient.Email,
                    intent.IdempotencyKey),
                cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception)
        {
            await ScheduleRetryAsync(intent.Id, outcomeUnknown: true, cancellationToken: CancellationToken.None);
            return true;
        }

        switch (result.Outcome)
        {
            case SavedSearchEmailSendOutcome.Accepted when !string.IsNullOrWhiteSpace(result.ProviderMessageId):
                await MarkAcceptedAsync(intent.Id, result.ProviderMessageId, cancellationToken);
                break;
            case SavedSearchEmailSendOutcome.Accepted:
            case SavedSearchEmailSendOutcome.OutcomeUnknown:
                await ScheduleRetryAsync(intent.Id, outcomeUnknown: true, cancellationToken);
                break;
            case SavedSearchEmailSendOutcome.TransientFailure:
                await ScheduleRetryAsync(intent.Id, outcomeUnknown: false, cancellationToken);
                break;
            case SavedSearchEmailSendOutcome.PermanentFailure:
                await MarkPermanentFailedAsync(intent.Id, cancellationToken);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(result.Outcome));
        }

        return true;
    }

    private async Task<DeliveryEligibility?> ResolveEligibilityAsync(
        Guid matchId,
        CancellationToken cancellationToken)
    {
        return await (
                from match in _dbContext.SavedSearchAlertMatches.AsNoTracking()
                join savedSearch in _dbContext.SavedSearches.AsNoTracking()
                    on match.SavedSearchId equals savedSearch.Id
                where match.Id == matchId
                    && savedSearch.AlertEnabled
                    && savedSearch.EmailEachNewMatchEnabled
                select new DeliveryEligibility(savedSearch.Id, match.ListingId))
            .SingleOrDefaultAsync(cancellationToken);
    }

    private async Task<bool> BindRecipientAsync(
        Guid intentId,
        string email,
        CancellationToken cancellationToken)
    {
        var fingerprint = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(email.Trim().ToLowerInvariant())));
        var current = await LoadForOutcomeAsync(intentId, cancellationToken);
        if (IsTerminal(current.Status)) return false;
        if (!current.BindRecipientFingerprint(fingerprint)) return false;
        await _dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task SuppressAsync(Guid intentId, CancellationToken cancellationToken)
    {
        var current = await LoadForOutcomeAsync(intentId, cancellationToken);
        if (IsTerminal(current.Status)) return;
        current.MarkSuppressed();
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task MarkAcceptedAsync(
        Guid intentId,
        string providerMessageId,
        CancellationToken cancellationToken)
    {
        var current = await LoadForOutcomeAsync(intentId, cancellationToken);
        if (IsTerminal(current.Status)) return;
        current.MarkAccepted(providerMessageId);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task MarkPermanentFailedAsync(Guid intentId, CancellationToken cancellationToken)
    {
        var current = await LoadForOutcomeAsync(intentId, cancellationToken);
        if (IsTerminal(current.Status)) return;
        current.MarkPermanentFailed();
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ScheduleRetryAsync(
        Guid intentId,
        bool outcomeUnknown,
        CancellationToken cancellationToken)
    {
        var current = await LoadForOutcomeAsync(intentId, cancellationToken);
        if (IsTerminal(current.Status)) return;
        current.ScheduleRetry(DateTime.UtcNow.Add(ComputeRetryDelay(current.Id, current.AttemptCount)), outcomeUnknown);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<SavedSearchAlertDeliveryIntent> LoadForOutcomeAsync(
        Guid intentId,
        CancellationToken cancellationToken)
    {
        _dbContext.ChangeTracker.Clear();
        return await _dbContext.SavedSearchAlertDeliveryIntents
            .SingleAsync(x => x.Id == intentId, cancellationToken);
    }

    private TimeSpan ComputeRetryDelay(Guid intentId, int attemptCount)
    {
        var exponent = Math.Min(Math.Max(attemptCount - 1, 0), 16);
        var multiplier = Math.Pow(2d, exponent);
        var rawMilliseconds = Math.Min(
            _options.InitialRetryDelay.TotalMilliseconds * multiplier,
            _options.MaxRetryDelay.TotalMilliseconds);
        var bytes = intentId.ToByteArray();
        var seed = BitConverter.ToUInt32(bytes, 0) ^ unchecked((uint)attemptCount * 2654435761u);
        var jitterFraction = (seed % 21) / 100d;
        var withJitter = Math.Min(rawMilliseconds * (1d + jitterFraction), _options.MaxRetryDelay.TotalMilliseconds);
        return TimeSpan.FromMilliseconds(withJitter);
    }

    private static bool IsTerminal(SavedSearchAlertDeliveryStatus status) =>
        status is SavedSearchAlertDeliveryStatus.Delivered
            or SavedSearchAlertDeliveryStatus.PermanentFailed
            or SavedSearchAlertDeliveryStatus.Suppressed;

    private sealed record DeliveryEligibility(Guid SavedSearchId, Guid ListingId);
}
