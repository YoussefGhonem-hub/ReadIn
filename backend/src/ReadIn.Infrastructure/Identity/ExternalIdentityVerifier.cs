using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// Accepted <c>aud</c> values of Google and Apple ID tokens. A provider with no client id is turned off. These are public
/// identifiers, not secrets (ADR 0012).
/// </summary>
public sealed class ExternalAuthOptions
{
    public const string Section = "ExternalAuth";

    /// <summary>The web client id (also the audience on Android, passed as <c>serverClientId</c>) and the iOS client id.</summary>
    public ExternalProviderOptions Google { get; init; } = new();

    /// <summary>The app's bundle id for native iOS sign in, and the Services ID for the web.</summary>
    public ExternalProviderOptions Apple { get; init; } = new();
}

public sealed class ExternalProviderOptions
{
    public string[] ClientIds { get; init; } = [];
}

/// <summary>Where a provider publishes its signing keys, and what its tokens must contain.</summary>
internal sealed record ExternalProvider(string Name, string MetadataAddress, string[] Issuers, bool RequiresNonce)
{
    public static readonly ExternalProvider Google = new(
        ExternalProviders.Google,
        "https://accounts.google.com/.well-known/openid-configuration",
        ["https://accounts.google.com", "accounts.google.com"],
        RequiresNonce: false);

    /// <summary>Apple tokens must carry the SHA-256 of a nonce only the app knows, so a leaked token can't be replayed.</summary>
    public static readonly ExternalProvider Apple = new(
        ExternalProviders.Apple,
        "https://appleid.apple.com/.well-known/openid-configuration",
        ["https://appleid.apple.com"],
        RequiresNonce: true);
}

/// <summary>
/// Verifies Google and Apple ID tokens with their OpenID Connect keys (fetched and cached by
/// <see cref="ConfigurationManager{T}"/>, refreshed when a key rotates): RS256 signature, issuer, audience, lifetime and
/// nonce (ADR 0012). Firebase Auth isn't involved (ADR 0008).
/// </summary>
internal sealed class OidcExternalIdentityVerifier : IExternalIdentityVerifier
{
    private static readonly HttpClient Http = new(new SocketsHttpHandler { PooledConnectionLifetime = TimeSpan.FromMinutes(15) })
    {
        Timeout = TimeSpan.FromSeconds(10),
    };

    private readonly Dictionary<string, (ExternalProvider Provider, string[] Audiences, BaseConfigurationManager Keys)> _providers = [];
    private readonly JsonWebTokenHandler _handler = new();
    private readonly ILogger _logger;

    public OidcExternalIdentityVerifier(IOptions<ExternalAuthOptions> options, ILogger<OidcExternalIdentityVerifier> logger)
        : this(
            options.Value,
            provider => new ConfigurationManager<OpenIdConnectConfiguration>(
                provider.MetadataAddress,
                new OpenIdConnectConfigurationRetriever(),
                new HttpDocumentRetriever(Http) { RequireHttps = true }),
            logger)
    {
    }

    /// <param name="keys">Tests pass a static configuration with their own signing key.</param>
    internal OidcExternalIdentityVerifier(
        ExternalAuthOptions options, Func<ExternalProvider, BaseConfigurationManager> keys, ILogger logger)
    {
        _logger = logger;
        Add(ExternalProvider.Google, options.Google);
        Add(ExternalProvider.Apple, options.Apple);
        EnabledProviders = [.. _providers.Keys];

        void Add(ExternalProvider provider, ExternalProviderOptions settings)
        {
            var audiences = settings.ClientIds.Where(id => !string.IsNullOrWhiteSpace(id)).ToArray();
            if (audiences.Length > 0) _providers[provider.Name] = (provider, audiences, keys(provider));
        }
    }

    public IReadOnlyList<string> EnabledProviders { get; }

    public async Task<Result<ExternalIdentity>> VerifyAsync(string provider, string idToken, string? nonce, CancellationToken ct)
    {
        if (!_providers.TryGetValue(provider, out var settings)) return CredentialErrors.ProviderDisabled;

        var result = await _handler.ValidateTokenAsync(idToken, new TokenValidationParameters
        {
            ValidIssuers = settings.Provider.Issuers,
            ValidAudiences = settings.Audiences,
            ConfigurationManager = settings.Keys,
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            RequireExpirationTime = true,
            ClockSkew = TimeSpan.FromMinutes(2),
        });
        if (!result.IsValid || result.SecurityToken is not JsonWebToken token || string.IsNullOrEmpty(token.Subject))
        {
            _logger.LogInformation("Rejected a {Provider} ID token: {Reason}", provider, result.Exception?.GetType().Name ?? "no subject");
            return CredentialErrors.ExternalInvalid;
        }

        var tokenNonce = token.TryGetPayloadValue<string>("nonce", out var value) ? value : null;
        if (!NonceMatches(settings.Provider.RequiresNonce, tokenNonce, nonce))
        {
            _logger.LogInformation("Rejected a {Provider} ID token: nonce mismatch", provider);
            return CredentialErrors.ExternalInvalid;
        }

        var email = token.TryGetPayloadValue<string>("email", out var address) && !string.IsNullOrWhiteSpace(address)
            ? address.Trim().ToLowerInvariant()
            : null;
        var name = token.TryGetPayloadValue<string>("name", out var fullName) && !string.IsNullOrWhiteSpace(fullName) ? fullName : null;
        return new ExternalIdentity(provider, token.Subject, email, email is not null && IsTrue(token, "email_verified"), name);
    }

    /// <summary>
    /// The token must hold the SHA-256 (hex) of the raw nonce the client sends us. Accepting the raw value itself would let
    /// anyone holding a leaked token copy the nonce out of its payload.
    /// </summary>
    internal static bool NonceMatches(bool required, string? inToken, string? raw)
    {
        if (inToken is null) return !required && string.IsNullOrEmpty(raw);
        if (string.IsNullOrEmpty(raw)) return false;

        var expected = Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(raw)));
        return CryptographicOperations.FixedTimeEquals(
            Encoding.ASCII.GetBytes(expected), Encoding.ASCII.GetBytes(inToken.ToLowerInvariant()));
    }

    /// <summary>Google sends <c>email_verified</c> as a JSON boolean, Apple as the string <c>"true"</c>.</summary>
    private static bool IsTrue(JsonWebToken token, string claim) =>
        token.TryGetClaim(claim, out var value) && bool.TryParse(value.Value, out var flag) && flag;
}
