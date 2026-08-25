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

        var rows = await _dbContext.Leads
            .AsNoTracking()
            .Join(
                _dbContext.Listings.AsNoTracking().Where(listing => listing.SellerId == sellerId),
                lead => lead.ListingId,
                listing => listing.Id,
                (lead, listing) => new { Lead = lead, ListingTitle = listing.Title })
            .OrderByDescending(item => item.Lead.CreatedAtUtc)
            .ThenByDescending(item => item.Lead.Id)
            .Select(item => new
            {
                item.Lead.Id,
                item.Lead.ListingId,
                item.ListingTitle,
                BuyerUserId = item.Lead.UserId,
                item.Lead.Channel,
                item.Lead.CreatedAtUtc,
                item.Lead.ContactedAtUtc,
                item.Lead.ClosedAtUtc,
                item.Lead.Outcome
            })
            .ToListAsync(cancellationToken);

        return rows
            .Select(item => new SellerLeadDto(
                item.Id,
                item.ListingId,
                item.ListingTitle,
                item.BuyerUserId,
                item.Channel,
                item.CreatedAtUtc,
                item.ContactedAtUtc,
                item.ClosedAtUtc,
                item.Outcome?.ToString()))
            .ToList();
    }
}
