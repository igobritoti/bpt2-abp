using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[AllowAnonymous]
public class LeadAppService : ILeadAppService, ITransientDependency
{
    private const string WhatsAppChannel = "WhatsApp";

    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;
    private readonly IPublicListingQuery _publicListings;

    public LeadAppService(
        MarketplaceDbContext dbContext,
        ICurrentUser currentUser,
        IPublicListingQuery publicListings)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _publicListings = publicListings;
    }

    public async Task<LeadDto> CreateAsync(Guid listingId, CancellationToken cancellationToken = default)
    {
        if (await _publicListings.GetAsync(listingId, cancellationToken) is null)
        {
            throw new EntityNotFoundException<Listing>(listingId);
        }

        var lead = new Lead(Guid.NewGuid(), listingId, _currentUser.Id, WhatsAppChannel, DateTime.UtcNow);
        await _dbContext.Leads.AddAsync(lead, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new LeadDto(lead.Id, lead.ListingId, lead.UserId, lead.Channel, lead.CreatedAtUtc);
    }
}
