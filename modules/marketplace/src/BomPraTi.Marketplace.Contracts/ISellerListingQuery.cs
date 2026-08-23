namespace BomPraTi.Marketplace.Contracts;

public interface ISellerListingQuery
{
    Task<IReadOnlyList<ListingDto>> GetMineAsync(CancellationToken cancellationToken = default);
}
