using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace BomPraTi.Services;

public static class ResendSvixWebhookVerifier
{
    public static readonly TimeSpan DefaultTolerance = TimeSpan.FromMinutes(5);

    public static bool Verify(
        string secret,
        string eventId,
        string timestamp,
        string signatureHeader,
        string rawBody,
        DateTimeOffset now,
        TimeSpan? tolerance = null)
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

        if ((now - signedAt).Duration() > (tolerance ?? DefaultTolerance))
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
}
