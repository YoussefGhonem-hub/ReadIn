using System.Collections.Concurrent;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Stands in for Google's token endpoint (the real client has its own unit tests). The code <c>code:{token}</c> trades for
/// the ID token <c>{token}</c>, which <see cref="FakeExternalIdentityVerifier"/> then reads; <c>google-down</c> means Google
/// is unreachable; anything else is rejected. Every code is recorded.
/// </summary>
internal sealed class FakeGoogleCodeExchanger : IGoogleCodeExchanger
{
    public const string Prefix = "code:";
    public const string Down = "google-down";

    public ConcurrentQueue<string> Exchanged { get; } = new();

    public bool IsConfigured => true;

    public Task<Result<string>> ExchangeAsync(string authorizationCode, CancellationToken ct)
    {
        Exchanged.Enqueue(authorizationCode);
        Result<string> result = authorizationCode switch
        {
            Down => CredentialErrors.ExternalUnavailable,
            _ when authorizationCode.StartsWith(Prefix, StringComparison.Ordinal) => authorizationCode[Prefix.Length..],
            _ => CredentialErrors.ExternalInvalid,
        };
        return Task.FromResult(result);
    }
}
