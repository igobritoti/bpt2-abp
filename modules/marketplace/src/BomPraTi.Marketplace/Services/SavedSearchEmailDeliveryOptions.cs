namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchEmailDeliveryOptions
{
    public bool Enabled { get; set; }
    public TimeSpan IdleDelay { get; set; } = TimeSpan.FromSeconds(15);
    public TimeSpan LeaseDuration { get; set; } = TimeSpan.FromMinutes(2);
    public TimeSpan InitialRetryDelay { get; set; } = TimeSpan.FromSeconds(30);
    public TimeSpan MaxRetryDelay { get; set; } = TimeSpan.FromMinutes(30);
}
