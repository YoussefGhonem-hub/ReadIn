using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Stands in for Google and Apple, whose real tokens can't be minted in tests (the real verifier has its own unit tests).
/// A token is <c>subject</c>, <c>subject|email</c> (a verified email) or <c>subject|email|unverified</c>; <c>invalid</c>
/// fails, and Apple tokens also need <see cref="AppleNonce"/>.
/// </summary>
internal sealed class FakeExternalIdentityVerifier : IExternalIdentityVerifier
{
    public const string AppleNonce = "test-nonce";
    public const string AppleClientId = "app.readin.readin";

    public IReadOnlyList<string> EnabledProviders { get; } = ExternalProviders.All;

    public Task<Result<ExternalIdentity>> VerifyAsync(string provider, string idToken, string? nonce, CancellationToken ct)
    {
        var parts = idToken.Split('|');
        if (parts[0] == "invalid" || (provider == ExternalProviders.Apple && nonce != AppleNonce))
            return Task.FromResult<Result<ExternalIdentity>>(CredentialErrors.ExternalInvalid);

        var email = parts.Length > 1 ? parts[1] : null;
        var verified = email is not null && (parts.Length < 3 || parts[2] != "unverified");
        return Task.FromResult<Result<ExternalIdentity>>(
            new ExternalIdentity(provider, parts[0], email, verified, Name: null, ClientId: provider == ExternalProviders.Apple ? AppleClientId : "google-client"));
    }
}
