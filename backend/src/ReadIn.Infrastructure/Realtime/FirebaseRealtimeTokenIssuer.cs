using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Realtime;

/// <summary>
/// Custom tokens from the Firebase Admin SDK (ADR 0008). With the real project they are signed locally with the
/// <c>Firebase:ServiceAccountJson</c> key, or, keyless, through the IAM <c>signBlob</c> API as the host's service account
/// (docs/setup/firebase.md). With the emulator the SDK mints unsigned tokens, which only the Auth emulator accepts.
/// </summary>
internal sealed partial class FirebaseRealtimeTokenIssuer(IOptions<FirebaseOptions> options, ILogger<FirebaseRealtimeTokenIssuer> logger)
    : IRealtimeTokenIssuer
{
    /// <summary>A named app, so it never clashes with another Firebase app in the process (e.g. a future FCM sender).</summary>
    internal const string AppName = "readin-realtime";

    /// <summary>The Admin SDK switches token signing to the emulator only through this variable.</summary>
    internal const string AuthEmulatorVariable = "FIREBASE_AUTH_EMULATOR_HOST";

    private static readonly Lock AppGate = new();

    public async Task<Result<string>> IssueAsync(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var auth = FirebaseAuth.GetAuth(GetOrCreateApp(options.Value));
            // The uid is the id the clients put in `/live/users/{id}` (a lowercase GUID), so the rules match it.
            return await auth.CreateCustomTokenAsync(userId.ToString(), cancellationToken);
        }
        catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
        {
            LogIssueFailed(logger, ex, userId);
            return RealtimeErrors.Unavailable;
        }
    }

    internal static FirebaseApp GetOrCreateApp(FirebaseOptions firebase)
    {
        lock (AppGate)
        {
            if (FirebaseApp.GetInstance(AppName) is { } existing) return existing;

            if (firebase.UseEmulator && string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(AuthEmulatorVariable)))
                Environment.SetEnvironmentVariable(AuthEmulatorVariable, firebase.AuthEmulatorHost);

            return FirebaseApp.Create(new AppOptions
            {
                ProjectId = string.IsNullOrWhiteSpace(firebase.ProjectId) ? null : firebase.ProjectId.Trim(),
                // The emulator never checks credentials; a placeholder keeps the SDK from looking for real ones.
                Credential = firebase.UseEmulator ? GoogleCredential.FromAccessToken("owner") : FirebaseCredentials.Create(firebase),
                ServiceAccountId = string.IsNullOrWhiteSpace(firebase.ServiceAccountId) ? null : firebase.ServiceAccountId.Trim(),
            }, AppName);
        }
    }

    [LoggerMessage(Level = LogLevel.Error, Message = "Could not create a Realtime Database token for user {UserId}; live updates are off for them")]
    private static partial void LogIssueFailed(ILogger logger, Exception exception, Guid userId);
}
