using System.Text.RegularExpressions;

namespace ReadIn.Application.Features.MobileApp;

/// <summary>
/// The forced-update policy of the mobile app, per store. The app compares its own version with
/// <see cref="MobileAppPlatformOptions.MinimumVersion"/> and asks the user to update; the server only reports it. Operators
/// change it without a deploy, e.g. <c>MobileApp__Ios__MinimumVersion=1.2.0</c>.
/// </summary>
public sealed class MobileAppOptions
{
    public const string Section = "MobileApp";

    public MobileAppPlatformOptions Ios { get; init; } = new();

    public MobileAppPlatformOptions Android { get; init; } = new();
}

public sealed partial class MobileAppPlatformOptions
{
    /// <summary>
    /// The oldest version that may still run, e.g. "1.2", "1.2.0" or "1.2.0+57" (build 57). Null or blank: no forced
    /// update, so an empty environment variable turns it off.
    /// </summary>
    public string? MinimumVersion { get; set; }

    /// <summary>The app's store page, an absolute https URL; null while the app has no listing there.</summary>
    public string? StoreUrl { get; set; }

    public string? MinimumVersionOrNull => Normalize(MinimumVersion);

    public string? StoreUrlOrNull => Normalize(StoreUrl);

    public bool HasValidMinimumVersion => MinimumVersionOrNull is not { } version || VersionPattern().IsMatch(version);

    public bool HasValidStoreUrl => StoreUrlOrNull is not { } url ||
        Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps;

    private static string? Normalize(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    /// <summary>Up to three numbers and an optional build number; ASCII digits only.</summary>
    [GeneratedRegex(@"^[0-9]+(\.[0-9]+){0,2}(\+[0-9]+)?\z")]
    private static partial Regex VersionPattern();
}
