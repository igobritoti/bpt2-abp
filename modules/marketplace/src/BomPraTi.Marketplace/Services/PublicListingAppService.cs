using BomPraTi.Marketplace.Contracts;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Marketplace.Services;

[AllowAnonymous]
public sealed class PublicListingAppService : IPublicListingAppService, ITransientDependency
{
    private readonly IPublicListingQuery _query;

    public PublicListingAppService(IPublicListingQuery query)
    {
        _query = query;
    }

    public Task<PublicListingDto?> GetAsync(Guid listingId, CancellationToken cancellationToken = default) =>
        _query.GetAsync(listingId, cancellationToken);

    public Task<IReadOnlyList<PublicListingDto>> GetListAsync(
        PublicListingSearchInput input,
        CancellationToken cancellationToken = default) =>
        _query.SearchAsync(input, cancellationToken);
}
