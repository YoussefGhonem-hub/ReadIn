using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace ReadIn.Infrastructure.Identity;

public sealed class FirebaseOptions
{
    public const string Section = "Firebase";

    public string ProjectId { get; set; } = "demo-readin";

    /// <summary>Development/Testing only: trust unsigned tokens from the Auth emulator and point the Admin SDK at it.</summary>
    public bool UseEmulator { get; set; }

    public string AuthEmulatorHost { get; set; } = "127.0.0.1:9099";

    public string? StorageBucket { get; set; }
}

/// <summary>Creates/updates Firebase Auth users for seeding (SPEC §18.3).</summary>
public interface IIdentityProvisioner
{
    /// <returns>false when Firebase is not configured or unreachable.</returns>
    Task<bool> EnsureUserAsync(string uid, string email, string displayName, string? password, bool disabled, CancellationToken ct);
}

internal sealed partial class FirebaseIdentityProvisioner(IOptions<FirebaseOptions> options, ILogger<FirebaseIdentityProvisioner> logger)
    : IIdentityProvisioner
{
    private static readonly Lock InitLock = new();
    private FirebaseAuth? _auth;
    private bool _unavailable;

    public async Task<bool> EnsureUserAsync(string uid, string email, string displayName, string? password, bool disabled, CancellationToken ct)
    {
        var auth = GetAuth();
        if (auth is null) return false;

        try
        {
            try
            {
                await auth.GetUserAsync(uid, ct);
                await auth.UpdateUserAsync(new UserRecordArgs
                {
                    Uid = uid,
                    Email = email,
                    DisplayName = displayName,
                    EmailVerified = true,
                    Disabled = disabled,
                    Password = password,
                }, ct);
            }
            catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
            {
                await auth.CreateUserAsync(new UserRecordArgs
                {
                    Uid = uid,
                    Email = email,
                    DisplayName = displayName,
                    EmailVerified = true,
                    Disabled = disabled,
                    Password = password,
                }, ct);
            }
            return true;
        }
        catch (Exception ex) when (ex is FirebaseException or HttpRequestException or TaskCanceledException)
        {
            LogUnreachable(logger, ex, email);
            _unavailable = true;
            return false;
        }
    }

    private FirebaseAuth? GetAuth()
    {
        if (_auth is not null || _unavailable) return _auth;

        lock (InitLock)
        {
            var settings = options.Value;
            var app = FirebaseApp.GetInstance("readin-admin");
            if (app is null)
            {
                GoogleCredential credential;
                if (settings.UseEmulator)
                {
                    // The Admin SDK talks to the emulator when this variable is set; any token is accepted.
                    Environment.SetEnvironmentVariable("FIREBASE_AUTH_EMULATOR_HOST", settings.AuthEmulatorHost);
                    credential = GoogleCredential.FromAccessToken("owner");
                }
                else
                {
                    try
                    {
                        credential = GoogleCredential.GetApplicationDefault();
                    }
                    catch (InvalidOperationException ex)
                    {
                        LogNotConfigured(logger, ex);
                        _unavailable = true;
                        return null;
                    }
                }

                app = FirebaseApp.Create(new AppOptions { Credential = credential, ProjectId = settings.ProjectId }, "readin-admin");
            }

            _auth = FirebaseAuth.GetAuth(app);
            return _auth;
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Firebase Auth is unreachable while provisioning {Email}; seeded users won't be able to sign in. Is the emulator running (firebase emulators:start)?")]
    private static partial void LogUnreachable(ILogger logger, Exception exception, string email);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Firebase Admin credentials are not configured (GOOGLE_APPLICATION_CREDENTIALS); skipping Firebase user provisioning")]
    private static partial void LogNotConfigured(ILogger logger, Exception exception);
}
