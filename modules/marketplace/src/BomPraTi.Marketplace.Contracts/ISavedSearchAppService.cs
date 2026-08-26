using Volo.Abp.Application.Services;

namespace BomPraTi.Marketplace.Contracts;

public interface ISavedSearchAppService : IApplicationService
{
    Task<SavedSearchDto> CreateAsync(
        SavedSearchCriteriaInput input,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<SavedSearchDto>> GetMineAsync(CancellationToken cancellationToken = default);

    Task<SavedSearchDto> SetAlertEnabledAsync(
        Guid id,
        bool enabled,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<SavedSearchAlertMatchDto>> GetMatchesAsync(
        Guid id,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
