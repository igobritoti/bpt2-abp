using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IModerationListingCommandService : IApplicationService
{
    Task<ListingDto> WithdrawAsync(Guid listingId, CancellationToken cancellationToken = default);
    Task<ListingDto> RestoreAsync(Guid listingId, CancellationToken cancellationToken = default);
}
