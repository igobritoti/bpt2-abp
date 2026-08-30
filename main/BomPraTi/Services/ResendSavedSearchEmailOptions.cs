namespace BomPraTi.Services;

public sealed class ResendSavedSearchEmailOptions
{
    public bool Enabled { get; set; }
    public string ApiKey { get; set; } = string.Empty;
    public string From { get; set; } = string.Empty;
    public string PublicWebBaseUrl { get; set; } = string.Empty;
    public string Endpoint { get; set; } = "https://api.resend.com/emails";
    public TimeSpan RequestTimeout { get; set; } = TimeSpan.FromSeconds(15);
    public string WebhookSecret { get; set; } = string.Empty;
}
