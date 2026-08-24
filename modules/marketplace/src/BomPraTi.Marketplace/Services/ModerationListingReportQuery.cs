using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

[Authorize(Roles = "admin")]
public class ModerationListingReportQuery : IModerationListingReportQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;

    public ModerationListingReportQuery(MarketplaceDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyList<ModerationListingReportDto>> GetAsync(CancellationToken cancellationToken = default)
    {
        return await (
            from report in _dbContext.ListingReports.AsNoTracking()
            join listing in _dbContext.Listings.AsNoTracking() on report.ListingId equals listing.Id
            orderby report.CreatedAtUtc descending, report.Id descending
            select new ModerationListingReportDto(
                report.Id,
                listing.Id,
                listing.Title,
                listing.Status.ToString(),
                report.CreatedAtUtc))
            .ToListAsync(cancellationToken);
    }
}
