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
public class ListingReportAppService : IListingReportAppService, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;
    private readonly IPublicListingQuery _publicListings;

    public ListingReportAppService(
        MarketplaceDbContext dbContext,
        ICurrentUser currentUser,
        IPublicListingQuery publicListings)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _publicListings = publicListings;
    }

    public async Task ReportAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            throw new EntityNotFoundException<Listing>(listingId);
        }

        var exists = await _dbContext.ListingReports
            .AsNoTracking()
            .AnyAsync(x => x.UserId == userId && x.ListingId == listingId, cancellationToken);
        if (exists)
        {
            return;
        }

        await _dbContext.ListingReports.AddAsync(
            new ListingReport(Guid.NewGuid(), userId, listingId, DateTime.UtcNow),
            cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> GetIsReportedAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        return await _dbContext.ListingReports
            .AsNoTracking()
            .AnyAsync(x => x.UserId == userId && x.ListingId == listingId, cancellationToken);
    }

    private Guid CurrentUserId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated Buyer is required.");
}
