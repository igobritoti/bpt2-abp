using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using BomPraTi.Marketplace.Contracts;
using BomPraTi.Marketplace.Data;
using BomPraTi.Marketplace.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Entities;
using Volo.Abp.Users;

namespace BomPraTi.Marketplace.Services;

[Authorize]
public class SavedSearchAppService : ISavedSearchAppService, ITransientDependency
{
    private readonly MarketplaceDbContext _dbContext;
    private readonly ICurrentUser _currentUser;

    public SavedSearchAppService(MarketplaceDbContext dbContext, ICurrentUser currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<SavedSearchDto> CreateAsync(
        SavedSearchCriteriaInput input,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(input);
        var userId = CurrentUserId();
        var criteria = Normalize(input);
        var criteriaKey = BuildCriteriaKey(criteria);

        var existing = await _dbContext.SavedSearches
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.UserId == userId && x.CriteriaKey == criteriaKey,
                cancellationToken);
        if (existing is not null)
        {
            return ToDto(existing);
        }

        var savedSearch = new SavedSearch(
            Guid.NewGuid(),
            userId,
            criteriaKey,
            criteria.VehicleId,
            criteria.SellerId,
            criteria.Brand,
            criteria.Model,
            criteria.Color,
            criteria.City,
            criteria.StateCode,
            criteria.MinModelYear,
            criteria.MaxModelYear,
            criteria.MinPrice,
            criteria.MaxPrice,
            criteria.MinMileageKm,
            criteria.MaxMileageKm,
            criteria.Query,
            DateTime.UtcNow);

        await _dbContext.SavedSearches.AddAsync(savedSearch, cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(savedSearch);
    }

    public async Task<IReadOnlyList<SavedSearchDto>> GetMineAsync(
        CancellationToken cancellationToken = default)
    {
        var userId = CurrentUserId();
        var items = await _dbContext.SavedSearches
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .ThenBy(x => x.Id)
            .ToListAsync(cancellationToken);

        return items.Select(ToDto).ToList();
    }

    public async Task<SavedSearchDto> SetAlertEnabledAsync(
        Guid id,
        bool enabled,
        CancellationToken cancellationToken = default)
    {
        var savedSearch = await GetOwnedAsync(id, cancellationToken);
        savedSearch.SetAlertEnabled(enabled, DateTime.UtcNow);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(savedSearch);
    }

    public async Task<IReadOnlyList<SavedSearchAlertMatchDto>> GetMatchesAsync(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        _ = await GetOwnedAsync(id, cancellationToken);
        return await _dbContext.SavedSearchAlertMatches
            .AsNoTracking()
            .Where(x => x.SavedSearchId == id)
            .OrderByDescending(x => x.DetectedAtUtc)
            .ThenBy(x => x.Id)
            .Select(x => new SavedSearchAlertMatchDto(x.Id, x.SavedSearchId, x.ListingId, x.DetectedAtUtc))
            .ToListAsync(cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var savedSearch = await GetOwnedAsync(id, cancellationToken);
        var matches = await _dbContext.SavedSearchAlertMatches
            .Where(x => x.SavedSearchId == id)
            .ToListAsync(cancellationToken);
        _dbContext.SavedSearchAlertMatches.RemoveRange(matches);
        _dbContext.SavedSearches.Remove(savedSearch);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<SavedSearch> GetOwnedAsync(Guid id, CancellationToken cancellationToken)
    {
        var userId = CurrentUserId();
        var savedSearch = await _dbContext.SavedSearches
            .SingleOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);
        return savedSearch ?? throw new EntityNotFoundException<SavedSearch>(id);
    }

    private Guid CurrentUserId() =>
        _currentUser.Id ?? throw new UnauthorizedAccessException("An authenticated Buyer is required.");

    private static SavedSearchCriteriaInput Normalize(SavedSearchCriteriaInput input) =>
        input with
        {
            Brand = Clean(input.Brand),
            Model = Clean(input.Model),
            Color = Clean(input.Color),
            City = Clean(input.City),
            StateCode = Clean(input.StateCode)?.ToUpperInvariant(),
            Query = Clean(input.Query)
        };

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static string BuildCriteriaKey(SavedSearchCriteriaInput input)
    {
        static string TextKey(string? value) => value?.ToLowerInvariant() ?? string.Empty;
        static string IntKey(int? value) => value?.ToString(CultureInfo.InvariantCulture) ?? string.Empty;
        static string DecimalKey(decimal? value) => value?.ToString("G29", CultureInfo.InvariantCulture) ?? string.Empty;
        static string Part(string value) => $"{value.Length}:{value}";

        var canonical = string.Concat(
            Part(input.VehicleId?.ToString("D") ?? string.Empty),
            Part(input.SellerId?.ToString("D") ?? string.Empty),
            Part(TextKey(input.Brand)),
            Part(TextKey(input.Model)),
            Part(TextKey(input.Color)),
            Part(TextKey(input.City)),
            Part(TextKey(input.StateCode)),
            Part(IntKey(input.MinModelYear)),
            Part(IntKey(input.MaxModelYear)),
            Part(DecimalKey(input.MinPrice)),
            Part(DecimalKey(input.MaxPrice)),
            Part(IntKey(input.MinMileageKm)),
            Part(IntKey(input.MaxMileageKm)),
            Part(TextKey(input.Query)));

        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonical)));
    }

    private static SavedSearchDto ToDto(SavedSearch item) =>
        new(
            item.Id,
            item.VehicleId,
            item.SellerId,
            item.Brand,
            item.Model,
            item.Color,
            item.City,
            item.StateCode,
            item.MinModelYear,
            item.MaxModelYear,
            item.MinPrice,
            item.MaxPrice,
            item.MinMileageKm,
            item.MaxMileageKm,
            item.Query,
            item.AlertEnabled,
            item.AlertEnabledAtUtc,
            item.CreatedAtUtc);
}
