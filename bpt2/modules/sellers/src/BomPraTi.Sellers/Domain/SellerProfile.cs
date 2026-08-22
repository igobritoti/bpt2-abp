using Volo.Abp.Domain.Entities;

namespace BomPraTi.Sellers.Domain;

public sealed class SellerProfile : AggregateRoot<Guid>
{
    public string DisplayName { get; private set; } = null!;
    public string WhatsAppNumber { get; private set; } = null!;

    private SellerProfile() { }

    public SellerProfile(Guid id, string displayName, string whatsAppNumber) : base(id)
    {
        Update(displayName, whatsAppNumber);
    }

    public void Update(string displayName, string whatsAppNumber)
    {
        if (string.IsNullOrWhiteSpace(displayName))
        {
            throw new ArgumentException("Seller display name is required.", nameof(displayName));
        }

        var normalizedName = displayName.Trim();
        if (normalizedName.Length > 120)
        {
            throw new ArgumentException("Seller display name is too long.", nameof(displayName));
        }

        var digits = new string((whatsAppNumber ?? string.Empty).Where(char.IsDigit).ToArray());
        if (digits.Length is < 8 or > 15)
        {
            throw new ArgumentException("WhatsApp number must contain 8 to 15 digits including country code.", nameof(whatsAppNumber));
        }

        DisplayName = normalizedName;
        WhatsAppNumber = digits;
    }
}
