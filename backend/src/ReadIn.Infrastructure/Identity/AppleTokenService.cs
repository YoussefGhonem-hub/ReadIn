using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// Sign in with Apple REST API (SPEC F01). <c>POST /auth/token</c> exchanges an authorization code (single use, valid five
/// minutes) for a refresh token; <c>POST /auth/revoke</c> revokes it and answers 200 even for a token that was already
/// invalid. Both authenticate with a client secret: an ES256 JWT (<c>kid</c> = key id, <c>iss</c> = Team ID,
/// <c>aud</c> = https://appleid.apple.com, <c>sub</c> = the client id), which Apple accepts for up to six months; ours lives
/// ten minutes. Network errors, timeouts, 429 and 5xx are retried three times with back-off.
/// </summary>
internal sealed partial class AppleTokenService : IAppleTokenService
{
    internal const string ClientSecretAudience = "https://appleid.apple.com";

    /// <summary>Waits before the 2nd, 3rd and 4th attempt; tests make them zero.</summary>
    internal TimeSpan[] Backoff { get; init; } = [TimeSpan.FromMilliseconds(300), TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(3)];

    private readonly HttpClient _http;
    private readonly AppleProviderOptions _options;
    private readonly TimeProvider _clock;
    private readonly ILogger _logger;
    private readonly ECDsaSecurityKey? _key;
    private readonly JsonWebTokenHandler _tokens = new() { SetDefaultTimesOnTokenCreation = false };

    public AppleTokenService(HttpClient http, IOptions<ExternalAuthOptions> options, TimeProvider clock, ILogger<AppleTokenService> logger)
    {
        _http = http;
        _options = options.Value.Apple;
        _clock = clock;
        _logger = logger;
        try
        {
            _key = LoadKey(_options);
        }
        catch (Exception ex) when (ex is FormatException or CryptographicException or ArgumentException)
        {
            LogKeyInvalid(_logger, ex); // deleting Apple-linked accounts then answers 503 instead of skipping revocation
        }
    }

    public bool IsConfigured => _key is not null && !string.IsNullOrWhiteSpace(_options.TeamId);

    public async Task<Result<string>> ExchangeCodeAsync(string clientId, string authorizationCode, CancellationToken ct)
    {
        if (!IsConfigured) return UserErrors.DeletionUnavailable;

        using var response = await PostAsync("auth/token", clientId, new()
        {
            ["code"] = authorizationCode,
            ["grant_type"] = "authorization_code",
        }, ct);
        if (response is null) return UserErrors.DeletionUnavailable;

        var body = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            LogRejected(_logger, "token", (int)response.StatusCode, ErrorCode(body));
            return CredentialErrors.ExternalInvalid; // expired, reused or foreign code
        }

        using var json = JsonDocument.Parse(body);
        return json.RootElement.TryGetProperty("refresh_token", out var token) && token.GetString() is { Length: > 0 } refresh
            ? refresh
            : CredentialErrors.ExternalInvalid;
    }

    public async Task<Result> RevokeRefreshTokenAsync(string clientId, string refreshToken, CancellationToken ct)
    {
        if (!IsConfigured) return UserErrors.DeletionUnavailable;

        using var response = await PostAsync("auth/revoke", clientId, new()
        {
            ["token"] = refreshToken,
            ["token_type_hint"] = "refresh_token",
        }, ct);
        if (response is null) return UserErrors.DeletionUnavailable;
        if (response.IsSuccessStatusCode) return Result.Success();

        LogRejected(_logger, "revoke", (int)response.StatusCode, ErrorCode(await response.Content.ReadAsStringAsync(ct)));
        return UserErrors.DeletionUnavailable; // e.g. invalid_client: our secret is wrong, which a retry won't fix by itself
    }

    /// <returns>The final response, or null when Apple stayed unreachable (network error, timeout, 429 or 5xx).</returns>
    private async Task<HttpResponseMessage?> PostAsync(string path, string clientId, Dictionary<string, string> form, CancellationToken ct)
    {
        for (var attempt = 0; ; attempt++)
        {
            var transient = false;
            try
            {
                using var request = new HttpRequestMessage(HttpMethod.Post, path)
                {
                    Content = new FormUrlEncodedContent(new Dictionary<string, string>(form)
                    {
                        ["client_id"] = clientId,
                        ["client_secret"] = ClientSecret(clientId),
                    }),
                };
                var response = await _http.SendAsync(request, ct);
                if ((int)response.StatusCode < 500 && response.StatusCode != HttpStatusCode.TooManyRequests) return response;

                LogTransient(_logger, path, attempt + 1, $"HTTP {(int)response.StatusCode}");
                response.Dispose();
                transient = true;
            }
            catch (Exception ex) when (ex is HttpRequestException || (ex is TaskCanceledException && !ct.IsCancellationRequested))
            {
                LogTransient(_logger, path, attempt + 1, ex.GetType().Name);
                transient = true;
            }

            if (!transient || attempt == Backoff.Length) return null;
            await Task.Delay(Backoff[attempt], _clock, ct);
        }
    }

    internal string ClientSecret(string clientId)
    {
        var now = _clock.GetUtcNow().UtcDateTime;
        return _tokens.CreateToken(new SecurityTokenDescriptor
        {
            Issuer = _options.TeamId,
            Audience = ClientSecretAudience,
            Claims = new Dictionary<string, object> { [JwtRegisteredClaimNames.Sub] = clientId },
            IssuedAt = now,
            Expires = now.AddMinutes(10),
            SigningCredentials = new SigningCredentials(_key, SecurityAlgorithms.EcdsaSha256),
        });
    }

    /// <summary>Accepts the <c>.p8</c> file base64-encoded (what <c>SIWA_KEY_BASE64</c> holds), its PEM text or raw PKCS#8.</summary>
    private static ECDsaSecurityKey? LoadKey(AppleProviderOptions options)
    {
        if (string.IsNullOrWhiteSpace(options.PrivateKeyBase64) || string.IsNullOrWhiteSpace(options.KeyId)) return null;

        var value = options.PrivateKeyBase64.Trim();
        var ecdsa = ECDsa.Create();
        if (value.StartsWith("-----", StringComparison.Ordinal))
        {
            ecdsa.ImportFromPem(value);
        }
        else
        {
            var bytes = Convert.FromBase64String(value);
            var text = Encoding.UTF8.GetString(bytes);
            if (text.StartsWith("-----", StringComparison.Ordinal)) ecdsa.ImportFromPem(text);
            else ecdsa.ImportPkcs8PrivateKey(bytes, out _);
        }
        return new ECDsaSecurityKey(ecdsa) { KeyId = options.KeyId };
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

    [LoggerMessage(Level = LogLevel.Error, Message = "The Sign in with Apple private key (SIWA_KEY_BASE64) could not be read")]
    private static partial void LogKeyInvalid(ILogger logger, Exception exception);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Apple {Endpoint} answered HTTP {Status} ({Error})")]
    private static partial void LogRejected(ILogger logger, string endpoint, int status, string? error);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Apple {Path} attempt {Attempt} failed ({Reason})")]
    private static partial void LogTransient(ILogger logger, string path, int attempt, string reason);
}
