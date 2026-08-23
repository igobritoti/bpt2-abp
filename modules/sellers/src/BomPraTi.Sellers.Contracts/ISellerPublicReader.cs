namespace BomPraTi.Sellers.Contracts;

public interface ISellerPublicReader
{
    Task<SellerPublicContactDto?> GetAsync(Guid sellerId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<SellerPublicContactDto>> GetManyAsync(
        IReadOnlyCollection<Guid> sellerIds,
        CancellationToken cancellationToken = default);
}
