using Volo.Abp.Application.Services;

namespace BomPraTi.Sellers.Contracts;

public interface ISellerPublicQuery : IApplicationService
{
    Task<SellerPublicContactDto?> GetAsync(Guid sellerId, CancellationToken cancellationToken = default);
}
