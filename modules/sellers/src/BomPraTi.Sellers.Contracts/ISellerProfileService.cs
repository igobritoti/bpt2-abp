using Volo.Abp.Application.Services;

namespace BomPraTi.Sellers.Contracts;

public interface ISellerProfileService : IApplicationService
{
    Task<SellerProfileDto?> GetCurrentAsync(CancellationToken cancellationToken = default);
    Task<SellerProfileDto> UpsertAsync(UpdateSellerProfileInput input, CancellationToken cancellationToken = default);
}
