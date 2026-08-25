using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class SellerLeadCommandService : ISellerLeadCommandService, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;

    public SellerLeadCommandService(MarketplaceDbContext dbContext, ICurrentUser currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task MarkContactedAsync(Guid leadId, CancellationToken cancellationToken = default)
    {
        var lead = await GetOwnedLeadAsync(leadId, cancellationToken);

        lead.MarkContacted(DateTime.UtcNow);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task CloseAsync(Guid leadId, CloseSellerLeadInput input, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);

        var outcome = input.Outcome?.Trim().ToUpperInvariant() switch
        {
            "WON" => LeadOutcome.Won,
            "LOST" => LeadOutcome.Lost,
            _ => throw new ArgumentException("Outcome must be Won or Lost.", nameof(input))
        };

        var lead = await GetOwnedLeadAsync(leadId, cancellationToken);

        lead.Close(outcome, DateTime.UtcNow);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<Lead> GetOwnedLeadAsync(Guid leadId, CancellationToken cancellationToken)
    {
        var sellerId = _currentUser.Id
            ?? throw new UnauthorizedAccessException("An authenticated seller is required.");

        return await _dbContext.Leads
            .Join(
                _dbContext.Listings.Where(listing => listing.SellerId == sellerId),
                candidate => candidate.ListingId,
                listing => listing.Id,
                (candidate, listing) => candidate)
            .SingleOrDefaultAsync(candidate => candidate.Id == leadId, cancellationToken)
            ?? throw new EntityNotFoundException(typeof(Lead), leadId);
    }
}
