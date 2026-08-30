using BomPraTi.Marketplace.Services;
using BomPraTi.Services;
using Microsoft.Extensions.Configuration;

var apiKey = Environment.GetEnvironmentVariable("BPT_RESEND_API_KEY");
var from = Environment.GetEnvironmentVariable("BPT_RESEND_FROM");
var recipient = Environment.GetEnvironmentVariable("BPT_RESEND_SAFE_RECIPIENT");
var publicWebBaseUrl = Environment.GetEnvironmentVariable("BPT_PUBLIC_WEB_BASE_URL");

if (new[] { apiKey, from, recipient, publicWebBaseUrl }.Any(string.IsNullOrWhiteSpace))
{
    Console.WriteLine("RESEND_SAVED_SEARCH_EMAIL_PROBE=SKIP");
    Console.WriteLine("RESEND_SAVED_SEARCH_EMAIL_PROBE_REASON=external credentials/sender/safe recipient/public URL not configured");
    return;
}

var configuration = new ConfigurationManager
{
    ["SavedSearchEmailDelivery:Resend:Enabled"] = "true",
    ["SavedSearchEmailDelivery:Resend:ApiKey"] = apiKey,
    ["SavedSearchEmailDelivery:Resend:From"] = from,
    ["SavedSearchEmailDelivery:Resend:PublicWebBaseUrl"] = publicWebBaseUrl,
    ["SavedSearchEmailDelivery:Resend:RequestTimeout"] = "00:00:15"
};
var transport = new ResendSavedSearchEmailTransport(configuration);
var message = new SavedSearchEmailMessage(
    Guid.Parse("51000000-0000-0000-0000-000000000001"),
    Guid.Parse("52000000-0000-0000-0000-000000000001"),
    Guid.Parse("53000000-0000-0000-0000-000000000001"),
    recipient!,
    "bpt2-resend-saved-search-sandbox-probe-v1");

var first = await transport.SendAsync(message);
if (first.Outcome != SavedSearchEmailSendOutcome.Accepted || string.IsNullOrWhiteSpace(first.ProviderMessageId))
{
    throw new InvalidOperationException($"Resend probe did not return Accepted with provider id. Outcome={first.Outcome}");
}

var exactRetry = await transport.SendAsync(message);
if (exactRetry.Outcome != SavedSearchEmailSendOutcome.Accepted
    || string.IsNullOrWhiteSpace(exactRetry.ProviderMessageId)
    || !string.Equals(first.ProviderMessageId, exactRetry.ProviderMessageId, StringComparison.Ordinal))
{
    throw new InvalidOperationException(
        $"Resend exact retry did not converge to the original logical send. First={first.ProviderMessageId}; Retry={exactRetry.ProviderMessageId}; Outcome={exactRetry.Outcome}");
}

Console.WriteLine("RESEND_SAVED_SEARCH_EMAIL_PROBE=PASS");
Console.WriteLine("RESEND_SAVED_SEARCH_EMAIL_IDEMPOTENT_RETRY=PASS");
Console.WriteLine($"RESEND_SAVED_SEARCH_EMAIL_PROVIDER_MESSAGE_ID={first.ProviderMessageId}");
