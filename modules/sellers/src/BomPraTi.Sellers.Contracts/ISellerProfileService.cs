namespace BomPraTi.Sellers.Contracts;

public interface ISellerProfileService
{
    Task<SellerProfileDto?> GetCurrentAsync(CancellationToken cancellationToken = default);
    Task<SellerProfileDto> UpsertAsync(UpdateSellerProfileInput input, CancellationToken cancellationToken = default);
}
