using BomPraTi.Sellers.Contracts;
using BomPraTi.Sellers.Data;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Sellers.Services;

public sealed class SellerPublicReader : ISellerPublicReader, ITransientDependency
{
    private readonly SellersDbContext _dbContext;

    public SellerPublicReader(SellersDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<SellerPublicContactDto?> GetAsync(Guid sellerId, CancellationToken cancellationToken = default)
    {
        return _dbContext.SellerProfiles
            .AsNoTracking()
            .Where(x => x.Id == sellerId)
            .Select(x => new SellerPublicContactDto(x.Id, x.DisplayName, x.WhatsAppNumber))
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<SellerPublicContactDto>> GetManyAsync(
        IReadOnlyCollection<Guid> sellerIds,
        CancellationToken cancellationToken = default)
    {
        if (sellerIds.Count == 0)
        {
            return Array.Empty<SellerPublicContactDto>();
        }

        return await _dbContext.SellerProfiles
            .AsNoTracking()
            .Where(x => sellerIds.Contains(x.Id))
            .Select(x => new SellerPublicContactDto(x.Id, x.DisplayName, x.WhatsAppNumber))
            .ToListAsync(cancellationToken);
    }
}
