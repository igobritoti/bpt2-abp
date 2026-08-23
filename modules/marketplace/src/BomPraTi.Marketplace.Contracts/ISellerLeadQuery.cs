using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ISellerLeadQuery : IApplicationService
{
    Task<IReadOnlyList<SellerLeadDto>> GetMineAsync(CancellationToken cancellationToken = default);
}
