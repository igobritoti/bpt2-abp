using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface IListingCommandService : IApplicationService
{
    Task<ListingDto> CreateAsync(CreateListingInput input, CancellationToken cancellationToken = default);
    Task<ListingDto> UpdateAsync(Guid listingId, UpdateListingInput input, CancellationToken cancellationToken = default);
    Task<ListingDto> PublishAsync(Guid listingId, CancellationToken cancellationToken = default);
    Task<ListingDto> PauseAsync(Guid listingId, CancellationToken cancellationToken = default);
    Task<ListingDto> ArchiveAsync(Guid listingId, CancellationToken cancellationToken = default);
}
