namespace BomPraTi.Marketplace.Services;

public sealed class SavedSearchAlertRunnerOptions
{
    public bool Enabled { get; set; } = true;
    public TimeSpan IdleDelay { get; set; } = TimeSpan.FromSeconds(15);
    public TimeSpan MissingListingRetryDelay { get; set; } = TimeSpan.FromMinutes(5);
}
