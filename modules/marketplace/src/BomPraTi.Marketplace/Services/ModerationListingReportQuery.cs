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
        var rows = await (
            from report in _dbContext.ListingReports.AsNoTracking()
            join listing in _dbContext.Listings.AsNoTracking() on report.ListingId equals listing.Id
            orderby report.CreatedAtUtc descending, report.Id descending
            select new
            {
                ReportId = report.Id,
                ListingId = listing.Id,
                ListingTitle = listing.Title,
                ListingStatus = listing.Status,
                report.CreatedAtUtc
            })
            .ToListAsync(cancellationToken);

        return rows
            .Select(row => new ModerationListingReportDto(
                row.ReportId,
                row.ListingId,
                row.ListingTitle,
                row.ListingStatus.ToString(),
                row.CreatedAtUtc))
            .ToList();
    }
}
