using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// Trades the web button's Google authorization code for its ID token at <c>POST https://oauth2.googleapis.com/token</c>
/// (ADR 0012). The web gets the code from Google Identity Services' popup code flow, whose redirect URI is the literal
/// <c>postmessage</c>. A code works once, so nothing is retried: a 4xx means an expired, reused or foreign code; a 5xx,
/// 429, timeout or network error means Google is unreachable and the person can try again. The sign-in flow can send the
/// same credential twice ("not linked" → create an account or link one), so the ID token a code was traded for is kept
/// for ten minutes, in memory and keyed by the code's SHA-256; the token itself is still checked each time.
/// </summary>
internal sealed partial class GoogleCodeExchanger : IGoogleCodeExchanger
{
    private static readonly TimeSpan Reuse = TimeSpan.FromMinutes(10);

    private readonly HttpClient _http;
    private readonly GoogleProviderOptions _options;
    private readonly IMemoryCache _traded;
    private readonly ILogger _logger;

    public GoogleCodeExchanger(
        HttpClient http, IOptions<ExternalAuthOptions> options, IMemoryCache traded, ILogger<GoogleCodeExchanger> logger)
    {
        _http = http;
        _options = options.Value.Google;
        _traded = traded;
        _logger = logger;
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_options.ClientSecret) && _options.WebClientId is not null;

    public async Task<Result<string>> ExchangeAsync(string authorizationCode, CancellationToken ct)
    {
        if (!IsConfigured) return CredentialErrors.ProviderDisabled;

        var key = "google-code:" + Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(authorizationCode)));
        if (_traded.TryGetValue(key, out string? earlier) && earlier is not null) return earlier;

        HttpResponseMessage response;
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "token")
            {
                Content = new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    ["code"] = authorizationCode,
                    ["client_id"] = _options.WebClientId!,
                    ["client_secret"] = _options.ClientSecret!,
                    ["redirect_uri"] = "postmessage",
                    ["grant_type"] = "authorization_code",
                }),
            };
            response = await _http.SendAsync(request, ct);
        }
        catch (Exception ex) when (ex is HttpRequestException || (ex is TaskCanceledException && !ct.IsCancellationRequested))
        {
            LogUnreachable(_logger, ex.GetType().Name);
            return CredentialErrors.ExternalUnavailable;
        }

        using (response)
        {
            var body = await response.Content.ReadAsStringAsync(ct);
            if ((int)response.StatusCode >= 500 || response.StatusCode == HttpStatusCode.TooManyRequests)
            {
                LogUnreachable(_logger, $"HTTP {(int)response.StatusCode}");
                return CredentialErrors.ExternalUnavailable;
            }
            if (!response.IsSuccessStatusCode)
            {
                var error = ErrorCode(body);
                // invalid_client means our secret or client id is wrong: every web sign in fails until it is fixed.
                if (error == "invalid_client") LogMisconfigured(_logger, (int)response.StatusCode);
                else LogRejected(_logger, (int)response.StatusCode, error);
                return CredentialErrors.ExternalInvalid;
            }

            if (IdToken(body) is not { Length: > 0 } idToken) return CredentialErrors.ExternalInvalid;
            _traded.Set(key, idToken, Reuse);
            return idToken;
        }
    }

    private static string? IdToken(string body)
    {
        try
        {
            using var json = JsonDocument.Parse(body);
            return json.RootElement.TryGetProperty("id_token", out var token) ? token.GetString() : null;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static string? ErrorCode(string body)
    {
        try
        {
            using var json = JsonDocument.Parse(body);
            return json.RootElement.TryGetProperty("error", out var error) ? error.GetString() : null;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Google's token endpoint was unreachable ({Reason})")]
    private static partial void LogUnreachable(ILogger logger, string reason);

    [LoggerMessage(Level = LogLevel.Information, Message = "Google rejected a sign-in code: HTTP {Status} ({Error})")]
    private static partial void LogRejected(ILogger logger, int status, string? error);

    [LoggerMessage(Level = LogLevel.Error,
        Message = "Google rejected our web client (HTTP {Status}, invalid_client): check ExternalAuth:Google:ClientSecret")]
    private static partial void LogMisconfigured(ILogger logger, int status);
}
