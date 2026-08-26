using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class SavedSearchAlertMatch : Entity<Guid>
{
    public Guid SavedSearchId { get; private set; }
    public Guid ListingId { get; private set; }
    public DateTime DetectedAtUtc { get; private set; }

    private SavedSearchAlertMatch() { }

    public SavedSearchAlertMatch(Guid id, Guid savedSearchId, Guid listingId, DateTime detectedAtUtc)
        : base(id)
    {
        SavedSearchId = savedSearchId;
        ListingId = listingId;
        DetectedAtUtc = DateTime.SpecifyKind(detectedAtUtc, DateTimeKind.Utc);
    }
}
