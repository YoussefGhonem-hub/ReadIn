using FirebaseAdmin.Auth;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Realtime;

/// <summary>
/// Deletes a deleted account's Firebase data (SPEC §9.6): its Firebase Auth record through the same Admin SDK app that
/// mints the realtime custom tokens, and its <c>/live/users/{id}</c> node through the Realtime Database REST API.
/// </summary>
internal sealed partial class FirebaseRealtimeAccountData(
    RealtimeDatabaseClient database,
    IOptions<FirebaseOptions> options,
    ILogger<FirebaseRealtimeAccountData> logger) : IRealtimeAccountData
{
    public async Task<Result> DeleteIdentityAsync(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var auth = FirebaseAuth.GetAuth(FirebaseRealtimeTokenIssuer.GetOrCreateApp(options.Value));
            await auth.DeleteUserAsync(userId.ToString(), cancellationToken);
            return Result.Success();
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            return Result.Success(); // never asked for a realtime token
        }
        catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
        {
            LogIdentityNotDeleted(logger, ex, userId);
            return UserErrors.DeletionUnavailable;
        }
    }

    public async Task DeleteLiveDataAsync(Guid userId, CancellationToken cancellationToken) =>
        await database.DeleteAsync($"live/users/{userId}", cancellationToken);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete the Firebase Auth record of user {UserId}; the account is kept")]
    private static partial void LogIdentityNotDeleted(ILogger logger, Exception exception, Guid userId);
}
