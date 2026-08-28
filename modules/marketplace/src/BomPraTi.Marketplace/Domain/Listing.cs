using Volo.Abp;
using Volo.Abp.Authorization;
using Volo.Abp.Domain.Entities;

namespace BomPraTi.Marketplace.Domain;

public sealed class Listing : AggregateRoot<Guid>
{
    public Guid SellerId { get; private set; }
    public Guid VehicleId { get; private set; }
    public string Title { get; private set; } = null!;
    public decimal Price { get; private set; }
    public string Description { get; private set; } = string.Empty;
    public int? ManufactureYear { get; private set; }
    public int? MileageKm { get; private set; }
    public string? Color { get; private set; }
    public string City { get; private set; } = string.Empty;
    public string StateCode { get; private set; } = string.Empty;
    public ListingStatus Status { get; private set; }
    public DateTime? FirstPublishedAtUtc { get; private set; }

    private Listing() { }

    public Listing(Guid id, Guid sellerId, Guid vehicleId, string title, decimal price) : base(id)
    {
        SellerId = sellerId;
        VehicleId = vehicleId;
        Status = ListingStatus.Draft;
        ChangeTitle(title);
        ChangePrice(price);
    }

    public Listing(
        Guid id,
        Guid sellerId,
        Guid vehicleId,
        string title,
        decimal price,
        string description,
        int? manufactureYear,
        int? mileageKm,
        string? color,
        string city,
        string stateCode) : this(id, sellerId, vehicleId, title, price)
    {
        ChangeDetails(description, manufactureYear, mileageKm, color, city, stateCode);
    }

    public void EnsureOwnedBy(Guid sellerId)
    {
        if (SellerId != sellerId)
        {
            throw new AbpAuthorizationException("Listing does not belong to this seller.");
        }
    }

    public void ChangeTitle(string title)
    {
        EnsureMutable();
        if (string.IsNullOrWhiteSpace(title)) throw new ArgumentException("Listing title is required.", nameof(title));
        Title = title.Trim();
    }

    public void ChangePrice(decimal price)
    {
        EnsureMutable();
        if (price <= 0) throw new ArgumentOutOfRangeException(nameof(price));
        Price = price;
    }

    public void ChangeDetails(
        string description,
        int? manufactureYear,
        int? mileageKm,
        string? color,
        string city,
        string stateCode)
    {
        EnsureMutable();

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new ArgumentException("Listing description is required.", nameof(description));
        }

        var normalizedDescription = description.Trim();
        if (normalizedDescription.Length > 4000)
        {
            throw new ArgumentException("Listing description is too long.", nameof(description));
        }

        if (manufactureYear is < 1886 or > 2100)
        {
            throw new ArgumentOutOfRangeException(nameof(manufactureYear));
        }

        if (mileageKm < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(mileageKm));
        }

        var normalizedColor = string.IsNullOrWhiteSpace(color) ? null : color.Trim();
        if (normalizedColor?.Length > 64)
        {
            throw new ArgumentException("Listing color is too long.", nameof(color));
        }

        if (string.IsNullOrWhiteSpace(city))
        {
            throw new ArgumentException("Listing city is required.", nameof(city));
        }

        var normalizedCity = city.Trim();
        if (normalizedCity.Length > 120)
        {
            throw new ArgumentException("Listing city is too long.", nameof(city));
        }

        var normalizedState = (stateCode ?? string.Empty).Trim().ToUpperInvariant();
        if (normalizedState.Length != 2 || !normalizedState.All(char.IsLetter))
        {
            throw new ArgumentException("State code must contain exactly two letters.", nameof(stateCode));
        }

        Description = normalizedDescription;
        ManufactureYear = manufactureYear;
        MileageKm = mileageKm;
        Color = normalizedColor;
        City = normalizedCity;
        StateCode = normalizedState;
    }

    public void Publish(DateTime publishedAtUtc)
    {
        EnsureMutable();
        FirstPublishedAtUtc ??= DateTime.SpecifyKind(publishedAtUtc, DateTimeKind.Utc);
        Status = ListingStatus.Published;
    }

    public void Pause()
    {
        EnsureMutable();
        if (Status == ListingStatus.Draft)
        {
            throw new InvalidOperationException("A draft listing cannot be paused.");
        }
        Status = ListingStatus.Paused;
    }

    public void Archive()
    {
        if (Status == ListingStatus.Moderated)
        {
            throw new BusinessException("Marketplace:ListingModerated");
        }

        Status = ListingStatus.Archived;
    }

    public void Moderate()
    {
        if (Status != ListingStatus.Published)
        {
            throw new BusinessException("Marketplace:ListingModerationRequiresPublished");
        }

        Status = ListingStatus.Moderated;
    }

    public void RestoreFromModeration()
    {
        if (Status != ListingStatus.Moderated)
        {
            throw new BusinessException("Marketplace:ListingRestoreRequiresModerated");
        }

        Status = ListingStatus.Published;
    }

    private void EnsureMutable()
    {
        if (Status == ListingStatus.Archived)
        {
            throw new InvalidOperationException("An archived listing is immutable.");
        }

        if (Status == ListingStatus.Moderated)
        {
            throw new BusinessException("Marketplace:ListingModerated");
        }
    }
}
