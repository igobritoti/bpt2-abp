using BomPraTi.Sellers.Contracts;
using BomPraTi.Sellers.Domain;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Users;

namespace BomPraTi.Sellers.Services;

[Authorize]
public sealed class SellerProfileService : ISellerProfileService, ITransientDependency
{
    private readonly IRepository<SellerProfile, Guid> _profiles;
    private readonly ICurrentUser _currentUser;

    public SellerProfileService(IRepository<SellerProfile, Guid> profiles, ICurrentUser currentUser)
    {
        _profiles = profiles;
        _currentUser = currentUser;
    }

    public async Task<SellerProfileDto?> GetCurrentAsync(CancellationToken cancellationToken = default)
    {
        var sellerId = GetSellerId();
        var profile = await _profiles.FindAsync(sellerId, includeDetails: false, cancellationToken: cancellationToken);
        return profile is null ? null : ToDto(profile);
    }

    public async Task<SellerProfileDto> UpsertAsync(
        UpdateSellerProfileInput input,
        CancellationToken cancellationToken = default)
    {
        var sellerId = GetSellerId();
        var profile = await _profiles.FindAsync(sellerId, includeDetails: false, cancellationToken: cancellationToken);
        if (profile is null)
        {
            profile = new SellerProfile(sellerId, input.DisplayName, input.WhatsAppNumber);
            await _profiles.InsertAsync(profile, autoSave: true, cancellationToken: cancellationToken);
        }
        else
        {
            profile.Update(input.DisplayName, input.WhatsAppNumber);
            await _profiles.UpdateAsync(profile, autoSave: true, cancellationToken: cancellationToken);
        }

        return ToDto(profile);
    }

    private Guid GetSellerId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated seller is required.");

    private static SellerProfileDto ToDto(SellerProfile profile) =>
        new(profile.Id, profile.DisplayName, profile.WhatsAppNumber);
}
