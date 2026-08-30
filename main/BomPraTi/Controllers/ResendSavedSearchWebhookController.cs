using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BomPraTi.Marketplace.Services;
using BomPraTi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace BomPraTi.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/webhooks/resend/saved-search-email")]
public sealed class ResendSavedSearchWebhookController : ControllerBase
{
    private static readonly TimeSpan SignatureTolerance = TimeSpan.FromMinutes(5);
    private readonly SavedSearchEmailProviderEventProcessor _processor;
    private readonly IConfiguration _configuration;

    public ResendSavedSearchWebhookController(
        SavedSearchEmailProviderEventProcessor processor,
        IConfiguration configuration)
    {
        _processor = processor;
        _configuration = configuration;
    }

    [HttpPost]
    public async Task<IActionResult> PostAsync(CancellationToken cancellationToken)
    {
        var secret = _configuration["SavedSearchEmailDelivery:Resend:WebhookSecret"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable);
        }

        using var reader = new StreamReader(Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);
        var eventId = Request.Headers["svix-id"].ToString();
        var timestamp = Request.Headers["svix-timestamp"].ToString();
        var signature = Request.Headers["svix-signature"].ToString();

        if (!VerifySvix(secret, eventId, timestamp, signature, rawBody, DateTimeOffset.UtcNow))
        {
            return Unauthorized();
        }

        ResendWebhookPayload? payload;
        try
        {
            payload = JsonSerializer.Deserialize<ResendWebhookPayload>(
                rawBody,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }
        catch (JsonException)
        {
            return BadRequest();
        }

        if (payload is null
            || string.IsNullOrWhiteSpace(payload.Type)
            || string.IsNullOrWhiteSpace(payload.Data?.EmailId))
        {
            return BadRequest();
        }

        if (payload.Type is not ("email.delivered" or "email.bounced" or "email.complained" or "email.failed"))
        {
            return Ok();
        }

        await _processor.ProcessAsync(
            "resend",
            eventId,
            payload.Data.EmailId,
            payload.Type,
            cancellationToken);
        return Ok();
    }

    internal static bool VerifySvix(
        string secret,
        string eventId,
        string timestamp,
        string signatureHeader,
        string rawBody,
        DateTimeOffset now)
    {
        if (string.IsNullOrWhiteSpace(eventId)
            || string.IsNullOrWhiteSpace(timestamp)
            || string.IsNullOrWhiteSpace(signatureHeader)
            || !secret.StartsWith("whsec_", StringComparison.Ordinal)
            || !long.TryParse(timestamp, NumberStyles.None, CultureInfo.InvariantCulture, out var unixTimestamp))
        {
            return false;
        }

        DateTimeOffset signedAt;
        try
        {
            signedAt = DateTimeOffset.FromUnixTimeSeconds(unixTimestamp);
        }
        catch (ArgumentOutOfRangeException)
        {
            return false;
        }

        if ((now - signedAt).Duration() > SignatureTolerance)
        {
            return false;
        }

        byte[] key;
        try
        {
            key = Convert.FromBase64String(secret["whsec_".Length..]);
        }
        catch (FormatException)
        {
            return false;
        }

        var signedContent = Encoding.UTF8.GetBytes($"{eventId}.{timestamp}.{rawBody}");
        var expected = HMACSHA256.HashData(key, signedContent);

        foreach (var token in signatureHeader.Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            var separator = token.IndexOf(',');
            if (separator <= 0 || !string.Equals(token[..separator], "v1", StringComparison.Ordinal))
            {
                continue;
            }

            byte[] actual;
            try
            {
                actual = Convert.FromBase64String(token[(separator + 1)..]);
            }
            catch (FormatException)
            {
                continue;
            }

            if (actual.Length == expected.Length && CryptographicOperations.FixedTimeEquals(actual, expected))
            {
                return true;
            }
        }

        return false;
    }

    private sealed record ResendWebhookPayload(string? Type, ResendWebhookData? Data);
    private sealed record ResendWebhookData(
        [property: System.Text.Json.Serialization.JsonPropertyName("email_id")] string? EmailId);
}
