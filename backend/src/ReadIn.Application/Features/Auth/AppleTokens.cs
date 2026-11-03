using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth;

/// <summary>
/// Sign in with Apple tokens (SPEC F01, App Store guideline 5.1.1(v)). At Apple sign in or link, the app's one-time
/// authorization code is exchanged for a refresh token that is kept encrypted, so deleting the account later, from any
/// device, can revoke it. Deletion never skips revocation: when Apple can't be reached the account stays, and when no
/// token is available the client is asked to confirm with Apple, which yields a fresh code.
/// </summary>
internal sealed partial class AppleTokens(IAppleTokenService apple, IProviderTokenProtector protector, ILogger<AppleTokens> logger)
{
    /// <summary>Best effort: without a stored token the account only has to confirm with Apple when it is deleted.</summary>
    public async Task CaptureAsync(User user, ExternalIdentity identity, string? authorizationCode, CancellationToken ct)
    {
        if (identity.Provider != ExternalProviders.Apple || string.IsNullOrEmpty(authorizationCode) || identity.ClientId is null) return;
        if (!apple.IsConfigured || user.FindExternalLogin(ExternalProviders.Apple) is not { ProviderRefreshToken: null }) return;

        var exchanged = await apple.ExchangeCodeAsync(identity.ClientId, authorizationCode, ct);
        if (exchanged.IsFailure)
        {
            LogCaptureFailed(logger, user.Id, exchanged.Error.Code);
            return;
        }
        user.StoreProviderToken(ExternalProviders.Apple, identity.ClientId, protector.Protect(exchanged.Value));
    }

    /// <summary>
    /// Revokes every Apple token this account has before it goes away: the one from a fresh code (when the person just
    /// confirmed with Apple) and the stored one. Succeeds right away for accounts without Apple.
    /// </summary>
    public async Task<Result> RevokeAsync(User user, ExternalIdentity? confirmedWith, string? freshCode, CancellationToken ct)
    {
        if (user.FindExternalLogin(ExternalProviders.Apple) is not { } login) return Result.Success();
        if (!apple.IsConfigured)
        {
            LogNotConfigured(logger, user.Id);
            return UserErrors.DeletionUnavailable;
        }

        var tokens = new List<(string ClientId, string RefreshToken)>();
        if (confirmedWith is { Provider: ExternalProviders.Apple, ClientId: { } freshClientId } && !string.IsNullOrEmpty(freshCode))
        {
            var exchanged = await apple.ExchangeCodeAsync(freshClientId, freshCode, ct);
            if (exchanged.IsSuccess) tokens.Add((freshClientId, exchanged.Value));
            else if (exchanged.Error.Type == ErrorType.Unavailable) return exchanged.Error;
        }
        if (login is { ProviderRefreshToken: { } stored, ProviderClientId: { } storedClientId } && protector.Unprotect(stored) is { } token)
            tokens.Add((storedClientId, token));

        if (tokens.Count == 0) return CredentialErrors.AppleConfirmationRequired;

        foreach (var (clientId, refreshToken) in tokens)
        {
            var revoked = await apple.RevokeRefreshTokenAsync(clientId, refreshToken, ct);
            if (revoked.IsFailure) return revoked.Error;
        }
        return Result.Success();
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not keep the Apple token of user {UserId} ({Code}); deleting it will ask for Apple")]
    private static partial void LogCaptureFailed(ILogger logger, Guid userId, string code);

    [LoggerMessage(Level = LogLevel.Error, Message = "User {UserId} can't be deleted: the Sign in with Apple key isn't configured, so its token can't be revoked")]
    private static partial void LogNotConfigured(ILogger logger, Guid userId);
}
