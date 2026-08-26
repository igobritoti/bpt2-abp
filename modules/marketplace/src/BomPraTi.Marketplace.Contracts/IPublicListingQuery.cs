using Volo.Abp.Application.Dtos;

namespace BomPraTi.Marketplace.Contracts;

public interface IPublicListingQuery
{
    Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PublicListingDto>> GetManyAsync(
        IReadOnlyCollection<Guid> listingIds,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        Guid? vehicleId = null,
        string? query = null,
        int skip = 0,
        int take = 20,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PublicListingDto>> SearchAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default);

    Task<PagedResultDto<PublicListingDto>> SearchPageAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default);

    Task<bool> MatchesAsync(
        Guid listingId,
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default);
}
