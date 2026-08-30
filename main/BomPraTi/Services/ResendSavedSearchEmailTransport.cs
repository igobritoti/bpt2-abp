using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using BomPraTi.Marketplace.Services;
using Microsoft.Extensions.Configuration;
using Volo.Abp.DependencyInjection;

namespace BomPraTi.Services;

public sealed class ResendSavedSearchEmailTransport : ISavedSearchEmailTransport, ITransientDependency
{
    private static readonly HttpClient HttpClient = new();
    private readonly ResendSavedSearchEmailOptions _options;

    public ResendSavedSearchEmailTransport(IConfiguration configuration)
    {
        _options = new ResendSavedSearchEmailOptions();
        configuration.GetSection("SavedSearchEmailDelivery:Resend").Bind(_options);
    }

    public async Task<SavedSearchEmailSendResult> SendAsync(
        SavedSearchEmailMessage message,
        CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled
            || string.IsNullOrWhiteSpace(_options.ApiKey)
            || string.IsNullOrWhiteSpace(_options.From)
            || string.IsNullOrWhiteSpace(_options.PublicWebBaseUrl))
        {
            return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.TransientFailure);
        }

        var listingUrl = $"{_options.PublicWebBaseUrl.TrimEnd('/')}/anuncios/{message.ListingId:D}";
        using var request = new HttpRequestMessage(HttpMethod.Post, _options.Endpoint);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
        request.Headers.TryAddWithoutValidation("Idempotency-Key", message.IdempotencyKey);
        request.Content = JsonContent.Create(new
        {
            from = _options.From,
            to = new[] { message.RecipientEmail },
            subject = "Nova oferta para sua busca salva",
            text = $"Uma nova oferta compatível foi detectada. Abra o anúncio: {listingUrl}"
        });

        try
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(_options.RequestTimeout);
            using var response = await HttpClient.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                timeout.Token);

            if (response.IsSuccessStatusCode)
            {
                var payload = await response.Content.ReadFromJsonAsync<ResendSendResponse>(cancellationToken: cancellationToken);
                return string.IsNullOrWhiteSpace(payload?.Id)
                    ? new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.OutcomeUnknown)
                    : new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.Accepted, payload.Id);
            }

            if (response.StatusCode == HttpStatusCode.TooManyRequests
                || response.StatusCode == HttpStatusCode.RequestTimeout
                || (int)response.StatusCode >= 500)
            {
                return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.TransientFailure);
            }

            if (response.StatusCode == HttpStatusCode.Conflict)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                if (body.Contains("concurrent_idempotent_requests", StringComparison.OrdinalIgnoreCase))
                {
                    return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.TransientFailure);
                }
            }

            return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.PermanentFailure);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.OutcomeUnknown);
        }
        catch (HttpRequestException)
        {
            return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.OutcomeUnknown);
        }
        catch (JsonException)
        {
            return new SavedSearchEmailSendResult(SavedSearchEmailSendOutcome.OutcomeUnknown);
        }
    }

    private sealed record ResendSendResponse(string? Id);
}
