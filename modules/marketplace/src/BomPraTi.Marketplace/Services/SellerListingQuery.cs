using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

public sealed class SellerListingQuery : ISellerListingQuery, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;

    public SellerListingQuery(MarketplaceDbContext dbContext, ICurrentUser currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<IReadOnlyList<ListingDto>> GetMineAsync(CancellationToken cancellationToken = default)
    {
        var sellerId = _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");

        return await _dbContext.Listings
            .AsNoTracking()
            .Where(x => x.SellerId == sellerId)
            .OrderBy(x => x.Id)
            .Select(x => new ListingDto(
                x.Id,
                x.SellerId,
                x.VehicleId,
                x.Title,
                x.Price,
                x.Description,
                x.ManufactureYear,
                x.MileageKm,
                x.Color,
                x.City,
                x.StateCode,
                x.Status.ToString(),
                x.ConcurrencyStamp))
            .ToListAsync(cancellationToken);
    }
}
