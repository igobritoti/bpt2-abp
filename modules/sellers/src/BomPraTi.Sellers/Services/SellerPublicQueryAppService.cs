using BomPraTi.Sellers.Contracts;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Sellers.Services;

[AllowAnonymous]
[ExposeServices(typeof(ISellerPublicQuery))]
public sealed class SellerPublicQueryAppService : ISellerPublicQuery, ITransientDependency
{
    private readonly ISellerPublicReader _reader;

    public SellerPublicQueryAppService(ISellerPublicReader reader)
    {
        _reader = reader;
    }

    public Task<SellerPublicContactDto?> GetAsync(Guid sellerId, CancellationToken cancellationToken = default)
    {
        return _reader.GetAsync(sellerId, cancellationToken);
    }
}
