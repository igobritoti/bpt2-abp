namespace BomPraTi.Marketplace.Contracts;

public interface ISellerLeadQuery
{
    Task<IReadOnlyList<SellerLeadDto>> GetMineAsync(CancellationToken cancellationToken = default);
}
