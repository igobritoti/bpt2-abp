using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class SellerLeadQuery : ISellerLeadQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;

    public SellerLeadQuery(MarketplaceDbContext dbContext, ICurrentUser currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<IReadOnlyList<SellerLeadDto>> GetMineAsync(CancellationToken cancellationToken = default)
    {
        var sellerId = _currentUser.Id
            ?? throw new UnauthorizedAccessException("An authenticated seller is required.");

        return await _dbContext.Leads
            .AsNoTracking()
            .Join(
                _dbContext.Listings.AsNoTracking().Where(listing => listing.SellerId == sellerId),
                lead => lead.ListingId,
                listing => listing.Id,
                (lead, listing) => new { Lead = lead, ListingTitle = listing.Title })
            .OrderByDescending(item => item.Lead.CreatedAtUtc)
            .ThenByDescending(item => item.Lead.Id)
            .Select(item => new SellerLeadDto(
                item.Lead.Id,
                item.Lead.ListingId,
                item.ListingTitle,
                item.Lead.UserId,
                item.Lead.Channel,
                item.Lead.CreatedAtUtc))
            .ToListAsync(cancellationToken);
    }
}
