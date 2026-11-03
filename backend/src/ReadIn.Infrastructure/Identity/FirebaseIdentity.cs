using Google.Apis.Auth.OAuth2;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// Firebase is used for Cloud Messaging and the Realtime Database only (ADR 0008). Users sign in with phone + password
/// against this API (ADR 0007); Firebase Auth only mints the custom tokens that let clients read the Realtime Database.
/// </summary>
public sealed class FirebaseOptions
{
    public const string Section = "Firebase";

    public string ProjectId { get; set; } = "demo-readin";

    /// <summary>Development/Testing only: point the Admin SDK at the Emulator Suite.</summary>
    public bool UseEmulator { get; set; }

    public string AuthEmulatorHost { get; set; } = "127.0.0.1:9099";

    /// <summary>
    /// Realtime Database URL of the real project (e.g. <c>https://readin-default-rtdb.europe-west1.firebasedatabase.app</c>),
    /// used only for live media-processing signals (ADR 0011). Empty disables them; clients still poll.
    /// </summary>
    public string? DatabaseUrl { get; set; }

    /// <summary>Realtime Database emulator (<c>127.0.0.1:9000</c>) when <see cref="UseEmulator"/> is on. Empty disables the signals.</summary>
    public string? DatabaseEmulatorHost { get; set; }

    /// <summary>
    /// Admin SDK service-account key for the real project, as JSON or base64-encoded JSON. Kept in user-secrets locally and
    /// in the host's secret store on servers, never in the repo (docs/setup/firebase.md). When empty, Application Default
    /// Credentials are used.
    /// </summary>
    public string? ServiceAccountJson { get; set; }
}

/// <summary>Builds the Admin SDK credential for the real Firebase project.</summary>
public static class FirebaseCredentials
{
    public static GoogleCredential Create(FirebaseOptions options)
    {
        if (string.IsNullOrWhiteSpace(options.ServiceAccountJson)) return GoogleCredential.GetApplicationDefault();

        var value = options.ServiceAccountJson.Trim();
        var json = value.StartsWith('{') ? value : System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(value));
        return CredentialFactory.FromJson<ServiceAccountCredential>(json).ToGoogleCredential();
    }
}
