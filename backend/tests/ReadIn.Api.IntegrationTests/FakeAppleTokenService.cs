using System.Collections.Concurrent;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Stands in for Apple's token endpoints (the real client has its own unit tests). A code exchanges to
/// <c>refresh-{code}</c>; a code starting with <c>bad</c> is rejected; a token containing <c>apple-down</c> can't be revoked
/// because "Apple" is unreachable. Every call is recorded, so tests look for their own unique codes.
/// </summary>
internal sealed class FakeAppleTokenService : IAppleTokenService
{
    public ConcurrentQueue<(string ClientId, string Code)> Exchanged { get; } = new();
    public ConcurrentQueue<(string ClientId, string RefreshToken)> Revoked { get; } = new();

    public bool IsConfigured => true;

    public Task<Result<string>> ExchangeCodeAsync(string clientId, string authorizationCode, CancellationToken ct)
    {
        Exchanged.Enqueue((clientId, authorizationCode));
        return Task.FromResult<Result<string>>(authorizationCode.StartsWith("bad", StringComparison.Ordinal)
            ? CredentialErrors.ExternalInvalid
            : $"refresh-{authorizationCode}");
    }

    public Task<Result> RevokeRefreshTokenAsync(string clientId, string refreshToken, CancellationToken ct)
    {
        if (refreshToken.Contains("apple-down", StringComparison.Ordinal)) return Task.FromResult<Result>(UserErrors.DeletionUnavailable);
        Revoked.Enqueue((clientId, refreshToken));
        return Task.FromResult(Result.Success());
    }
}
