using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.UnitTests.Identity;

/// <summary>The real Google/Apple token checks, with a local key standing in for the providers' published keys.</summary>
public sealed class ExternalIdentityVerifierTests
{
    private const string GoogleClient = "web-client.apps.googleusercontent.com";
    private const string AppleClient = "app.readin.readin";
    private static readonly RsaSecurityKey ProviderKey = new(RSA.Create(2048)) { KeyId = "provider-key" };
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static OidcExternalIdentityVerifier Verifier(string[]? appleClients = null) => new(
        new ExternalAuthOptions
        {
            Google = new GoogleProviderOptions { ClientIds = [GoogleClient, "ios-client.apps.googleusercontent.com"] },
            Apple = new AppleProviderOptions { ClientIds = appleClients ?? [AppleClient] },
        },
        provider =>
        {
            var configuration = new OpenIdConnectConfiguration { Issuer = provider.Issuers[0] };
            configuration.SigningKeys.Add(ProviderKey);
            return new StaticConfigurationManager<OpenIdConnectConfiguration>(configuration);
        },
        NullLogger.Instance);

    private static string Token(
        string issuer = "https://accounts.google.com",
        string audience = GoogleClient,
        Dictionary<string, object>? claims = null,
        SecurityKey? key = null,
        DateTime? expires = null)
    {
        var expiresAt = expires ?? DateTime.UtcNow.AddHours(1);
        return new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = issuer,
            Audience = audience,
            Subject = new ClaimsIdentity([new Claim("sub", "provider-user-1")]),
            Claims = claims ?? new Dictionary<string, object> { ["email"] = "Mona@Example.com", ["email_verified"] = true, ["name"] = "Mona" },
            IssuedAt = expiresAt.AddHours(-1),
            NotBefore = expiresAt.AddHours(-1),
            Expires = expiresAt,
            SigningCredentials = new SigningCredentials(key ?? ProviderKey, SecurityAlgorithms.RsaSha256),
        });
    }

    private static string Sha256(string value) => Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    [Fact]
    public async Task A_valid_google_token_gives_the_identity()
    {
        var result = await Verifier().VerifyAsync(ExternalProviders.Google, Token(), nonce: null, Ct);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Be(new ExternalIdentity(
            ExternalProviders.Google, "provider-user-1", "mona@example.com", EmailVerified: true, Name: "Mona", ClientId: GoogleClient));
    }

    [Fact]
    public async Task Both_google_issuer_spellings_and_every_client_id_are_accepted()
    {
        var verifier = Verifier();

        (await verifier.VerifyAsync(ExternalProviders.Google, Token(issuer: "accounts.google.com"), null, Ct)).IsSuccess.Should().BeTrue();
        (await verifier.VerifyAsync(ExternalProviders.Google, Token(audience: "ios-client.apps.googleusercontent.com"), null, Ct))
            .IsSuccess.Should().BeTrue();
    }

    [Theory]
    [InlineData("wrong-audience")]
    [InlineData("wrong-issuer")]
    [InlineData("expired")]
    [InlineData("forged")]
    [InlineData("garbage")]
    public async Task Tokens_that_fail_any_check_are_rejected(string problem)
    {
        var token = problem switch
        {
            "wrong-audience" => Token(audience: "someone-elses-app"),
            "wrong-issuer" => Token(issuer: "https://evil.example.com"),
            "expired" => Token(expires: DateTime.UtcNow.AddMinutes(-10)),
            "forged" => Token(key: new RsaSecurityKey(RSA.Create(2048)) { KeyId = "provider-key" }),
            _ => "not-a-jwt",
        };

        var result = await Verifier().VerifyAsync(ExternalProviders.Google, token, null, Ct);

        result.Error.Should().Be(CredentialErrors.ExternalInvalid);
    }

    [Fact]
    public async Task Apple_tokens_must_carry_the_hash_of_the_apps_nonce()
    {
        var verifier = Verifier();
        var apple = Token("https://appleid.apple.com", AppleClient, new Dictionary<string, object>
        {
            ["email"] = "x1y2@privaterelay.appleid.com",
            ["email_verified"] = "true",
            ["nonce"] = Sha256("raw-nonce"),
        });

        var ok = await verifier.VerifyAsync(ExternalProviders.Apple, apple, "raw-nonce", Ct);
        ok.IsSuccess.Should().BeTrue();
        ok.Value.EmailVerified.Should().BeTrue("Apple sends email_verified as a string");
        ok.Value.Name.Should().BeNull();

        (await verifier.VerifyAsync(ExternalProviders.Apple, apple, null, Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid);
        (await verifier.VerifyAsync(ExternalProviders.Apple, apple, Sha256("raw-nonce"), Ct))
            .Error.Should().Be(CredentialErrors.ExternalInvalid, "the hash in the token is public; only the raw nonce proves it is the app");

        var noNonce = Token("https://appleid.apple.com", AppleClient, new Dictionary<string, object> { ["email_verified"] = "true" });
        (await verifier.VerifyAsync(ExternalProviders.Apple, noNonce, "raw-nonce", Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid);
    }

    [Fact]
    public async Task A_google_token_with_the_ios_sdks_own_nonce_is_accepted_but_a_nonce_the_app_sends_must_match()
    {
        var verifier = Verifier();
        // GoogleSignIn 9 on iOS puts a random nonce of its own in the token and never gives it to the app.
        var ios = Token(audience: "ios-client.apps.googleusercontent.com", claims: new Dictionary<string, object>
        {
            ["email"] = "mona@example.com",
            ["email_verified"] = true,
            ["nonce"] = "sdk-generated-random-value",
        });

        (await verifier.VerifyAsync(ExternalProviders.Google, ios, null, Ct)).IsSuccess.Should().BeTrue();
        (await verifier.VerifyAsync(ExternalProviders.Google, ios, "some-other-raw-nonce", Ct))
            .Error.Should().Be(CredentialErrors.ExternalInvalid, "a nonce the client sends must still match the token");

        var hashed = Token(claims: new Dictionary<string, object> { ["nonce"] = Sha256("raw-nonce") });
        (await verifier.VerifyAsync(ExternalProviders.Google, hashed, "raw-nonce", Ct)).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task A_google_token_is_not_accepted_as_an_apple_token()
    {
        var result = await Verifier().VerifyAsync(ExternalProviders.Apple, Token(audience: AppleClient), "raw-nonce", Ct);

        result.Error.Should().Be(CredentialErrors.ExternalInvalid);
    }

    [Fact]
    public async Task Providers_without_client_ids_are_off()
    {
        var verifier = Verifier(appleClients: []);

        verifier.EnabledProviders.Should().Equal(ExternalProviders.Google);
        (await verifier.VerifyAsync(ExternalProviders.Apple, Token(), "raw-nonce", Ct)).Error.Should().Be(CredentialErrors.ProviderDisabled);
    }

    [Fact]
    public async Task Unverified_emails_are_reported_as_such()
    {
        var token = Token(claims: new Dictionary<string, object> { ["email"] = "a@example.com", ["email_verified"] = false });

        var result = await Verifier().VerifyAsync(ExternalProviders.Google, token, null, Ct);

        result.Value.EmailVerified.Should().BeFalse();
    }
}
