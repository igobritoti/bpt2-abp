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
        var sellerId = _currentUser.Id
            ?? throw new UnauthorizedAccessException("An authenticated seller is required.");

        var lead = await _dbContext.Leads
            .Join(
                _dbContext.Listings.Where(listing => listing.SellerId == sellerId),
                candidate => candidate.ListingId,
                listing => listing.Id,
                (candidate, listing) => candidate)
            .SingleOrDefaultAsync(candidate => candidate.Id == leadId, cancellationToken)
            ?? throw new EntityNotFoundException(typeof(Lead), leadId);

        lead.MarkContacted(DateTime.UtcNow);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
