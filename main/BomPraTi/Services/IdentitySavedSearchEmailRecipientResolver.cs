using BomPraTi.Data;
using BomPraTi.Marketplace.Services;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Identity;

namespace BomPraTi.Services;

public sealed class IdentitySavedSearchEmailRecipientResolver : ISavedSearchEmailRecipientResolver, ITransientDependency
{
    private readonly BomPraTiDbContext _dbContext;

    public IdentitySavedSearchEmailRecipientResolver(BomPraTiDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<SavedSearchEmailRecipient?> ResolveVerifiedAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await _dbContext.Set<IdentityUser>()
            .AsNoTracking()
            .SingleOrDefaultAsync(x => x.Id == userId, cancellationToken);

        if (user is null
            || !user.IsActive
            || !user.EmailConfirmed
            || string.IsNullOrWhiteSpace(user.Email))
        {
            return null;
        }

        return new SavedSearchEmailRecipient(user.Email.Trim());
    }
}
