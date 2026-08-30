using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class SavedSearch : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public string CriteriaKey { get; private set; } = string.Empty;
    public Guid? VehicleId { get; private set; }
    public Guid? SellerId { get; private set; }
    public string? Brand { get; private set; }
    public string? Model { get; private set; }
    public string? Color { get; private set; }
    public string? City { get; private set; }
    public string? StateCode { get; private set; }
    public int? MinModelYear { get; private set; }
    public int? MaxModelYear { get; private set; }
    public decimal? MinPrice { get; private set; }
    public decimal? MaxPrice { get; private set; }
    public int? MinMileageKm { get; private set; }
    public int? MaxMileageKm { get; private set; }
    public string? Query { get; private set; }
    public bool AlertEnabled { get; private set; }
    public DateTime? AlertEnabledAtUtc { get; private set; }
    public bool EmailEachNewMatchEnabled { get; private set; }
    public DateTime? EmailEachNewMatchEnabledAtUtc { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    private SavedSearch() { }

    public SavedSearch(
        Guid id,
        Guid userId,
        string criteriaKey,
        Guid? vehicleId,
        Guid? sellerId,
        string? brand,
        string? model,
        string? color,
        string? city,
        string? stateCode,
        int? minModelYear,
        int? maxModelYear,
        decimal? minPrice,
        decimal? maxPrice,
        int? minMileageKm,
        int? maxMileageKm,
        string? query,
        DateTime createdAtUtc) : base(id)
    {
        UserId = userId;
        CriteriaKey = criteriaKey;
        VehicleId = vehicleId;
        SellerId = sellerId;
        Brand = brand;
        Model = model;
        Color = color;
        City = city;
        StateCode = stateCode;
        MinModelYear = minModelYear;
        MaxModelYear = maxModelYear;
        MinPrice = minPrice;
        MaxPrice = maxPrice;
        MinMileageKm = minMileageKm;
        MaxMileageKm = maxMileageKm;
        Query = query;
        AlertEnabled = false;
        EmailEachNewMatchEnabled = false;
        CreatedAtUtc = DateTime.SpecifyKind(createdAtUtc, DateTimeKind.Utc);
    }

    public void SetAlertEnabled(bool enabled, DateTime changedAtUtc)
    {
        if (enabled)
        {
            if (AlertEnabled && AlertEnabledAtUtc.HasValue)
            {
                return;
            }

            AlertEnabled = true;
            AlertEnabledAtUtc = DateTime.SpecifyKind(changedAtUtc, DateTimeKind.Utc);
            return;
        }

        if (!AlertEnabled && AlertEnabledAtUtc is null)
        {
            return;
        }

        AlertEnabled = false;
        AlertEnabledAtUtc = null;
    }

    public void SetEmailEachNewMatchEnabled(bool enabled, DateTime changedAtUtc)
    {
        if (enabled)
        {
            if (EmailEachNewMatchEnabled && EmailEachNewMatchEnabledAtUtc.HasValue)
            {
                return;
            }

            EmailEachNewMatchEnabled = true;
            EmailEachNewMatchEnabledAtUtc = DateTime.SpecifyKind(changedAtUtc, DateTimeKind.Utc);
            return;
        }

        if (!EmailEachNewMatchEnabled && EmailEachNewMatchEnabledAtUtc is null)
        {
            return;
        }

        EmailEachNewMatchEnabled = false;
        EmailEachNewMatchEnabledAtUtc = null;
    }
}
