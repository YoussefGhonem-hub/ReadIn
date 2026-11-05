using System.Net;
using ReadIn.Domain.Common;

namespace ReadIn.Domain.Users;

/// <summary>
/// One social link on a profile (SPEC F14), as stored in <c>Users.Links</c> (a JSON array, in the member's order).
/// <see cref="Platform"/> is one of <see cref="LinkPlatforms.All"/>; <see cref="Label"/> is set for <c>other</c> only.
/// </summary>
public sealed record ProfileLink(string Platform, string Url, string? Label = null);

/// <summary>The platforms of SPEC F14 (the API's lower-case <c>platform</c> values) and the hosts each one accepts.</summary>
public static class LinkPlatforms
{
    public const string LinkedIn = "linkedin";
    public const string X = "x";
    public const string Instagram = "instagram";
    public const string Facebook = "facebook";
    public const string YouTube = "youtube";
    public const string TikTok = "tiktok";
    public const string Snapchat = "snapchat";
    public const string Threads = "threads";
    public const string Telegram = "telegram";
    public const string GitHub = "github";
    public const string Medium = "medium";
    public const string Behance = "behance";

    /// <summary>Any https site.</summary>
    public const string Website = "website";

    /// <summary>Any https site, with the member's own label; the only platform that may repeat.</summary>
    public const string Other = "other";

    /// <summary>
    /// A named platform's hosts: the host itself or any subdomain of it (<c>www.</c>, <c>m.</c>, <c>eg.linkedin.com</c>).
    /// <see cref="Website"/> and <see cref="Other"/> accept any host.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, IReadOnlyList<string>> Hosts = new Dictionary<string, IReadOnlyList<string>>(StringComparer.Ordinal)
    {
        [LinkedIn] = ["linkedin.com", "lnkd.in"],
        [X] = ["x.com", "twitter.com"],
        [Instagram] = ["instagram.com", "instagr.am"],
        [Facebook] = ["facebook.com", "fb.com", "fb.me"],
        [YouTube] = ["youtube.com", "youtu.be"],
        [TikTok] = ["tiktok.com"],
        [Snapchat] = ["snapchat.com"],
        [Threads] = ["threads.net", "threads.com"],
        [Telegram] = ["t.me", "telegram.me"],
        [GitHub] = ["github.com"],
        [Medium] = ["medium.com"],
        [Behance] = ["behance.net"],
    };

    /// <summary>Every platform, in the SPEC's order.</summary>
    public static readonly IReadOnlyList<string> All =
        [LinkedIn, X, Instagram, Facebook, YouTube, TikTok, Snapchat, Threads, Telegram, GitHub, Medium, Behance, Website, Other];

    public static bool IsKnown(string? platform) => platform is not null && All.Contains(platform, StringComparer.Ordinal);

    /// <summary><paramref name="host"/> is one of the platform's hosts or a subdomain of one; always true for website and other.</summary>
    public static bool AllowsHost(string platform, string host)
    {
        if (!Hosts.TryGetValue(platform, out var hosts)) return true;
        host = host.TrimEnd('.').ToLowerInvariant();
        return hosts.Any(h => host == h || host.EndsWith("." + h, StringComparison.Ordinal));
    }
}

/// <summary>
/// The rules of a profile's links (SPEC F14; contract "Title and social links"). <see cref="Check"/> gives the normalized
/// links, or the validation codes keyed like the API's <c>errors</c> (<c>links</c>, <c>links[2].url</c>).
/// </summary>
public static class ProfileLinkRules
{
    public const int MaxLinks = 8;
    public const int MaxUrlLength = 500;
    public const int MinLabelLength = 2;
    public const int MaxLabelLength = 30;

    public const string TooMany = "link.too_many";
    public const string PlatformInvalid = "link.platform_invalid";
    public const string DuplicatePlatform = "link.duplicate_platform";
    public const string UrlRequired = "validation.required";
    public const string TooLong = "link.too_long";
    public const string HttpsRequired = "link.https_required";
    public const string UrlInvalid = "link.url_invalid";
    public const string HostMismatch = "link.host_mismatch";
    public const string LabelRequired = "link.label_required";
    public const string LabelInvalid = "link.label_invalid";
    public const string LabelNotAllowed = "link.label_not_allowed";

    /// <summary>Every link code, for the error-message table.</summary>
    public static readonly IReadOnlyList<string> Codes =
        [TooMany, PlatformInvalid, DuplicatePlatform, TooLong, HttpsRequired, UrlInvalid, HostMismatch, LabelRequired, LabelInvalid, LabelNotAllowed];

    /// <summary>
    /// Checks <paramref name="links"/> in order. Each link gets at most one code per part (the first rule it breaks), so
    /// the client shows one message under each field.
    /// </summary>
    public static Result<IReadOnlyList<ProfileLink>> Check(IReadOnlyList<ProfileLink> links)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.Ordinal);
        if (links.Count > MaxLinks) errors["links"] = [TooMany];

        var seen = new HashSet<string>(StringComparer.Ordinal);
        var normalized = new List<ProfileLink>(links.Count);
        for (var i = 0; i < links.Count; i++)
        {
            var link = links[i];
            var key = $"links[{i}]";
            var platform = link.Platform;

            if (!LinkPlatforms.IsKnown(platform)) errors[$"{key}.platform"] = [PlatformInvalid];
            else if (platform != LinkPlatforms.Other && !seen.Add(platform)) errors[$"{key}.platform"] = [DuplicatePlatform];

            var url = NormalizeUrl(link.Url);
            if (UrlProblem(platform, url) is { } urlCode) errors[$"{key}.url"] = [urlCode];

            var label = string.IsNullOrWhiteSpace(link.Label) ? null : link.Label.Trim();
            if (LabelProblem(platform, label) is { } labelCode) errors[$"{key}.label"] = [labelCode];

            normalized.Add(new ProfileLink(platform, url ?? string.Empty, platform == LinkPlatforms.Other ? label : null));
        }

        if (errors.Count > 0)
        {
            return Error.Validation("validation.failed", "Validation failed.") with { Details = errors };
        }
        return normalized;
    }

    /// <summary>Trimmed, with <c>https://</c> added when there is no scheme; null when empty.</summary>
    public static string? NormalizeUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url)) return null;
        var trimmed = url.Trim();
        return trimmed.Contains("://", StringComparison.Ordinal) ? trimmed : "https://" + trimmed;
    }

    private static string? UrlProblem(string? platform, string? url)
    {
        if (url is null) return UrlRequired;
        if (url.Length > MaxUrlLength) return TooLong;

        var scheme = url[..url.IndexOf("://", StringComparison.Ordinal)];
        if (!string.Equals(scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)) return HttpsRequired;

        if (url.Any(char.IsWhiteSpace) || url.Any(char.IsControl)) return UrlInvalid;
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme != Uri.UriSchemeHttps) return UrlInvalid;
        if (!string.IsNullOrEmpty(uri.UserInfo) || !uri.IsDefaultPort) return UrlInvalid;

        var host = uri.IdnHost.TrimEnd('.');
        if (uri.HostNameType != UriHostNameType.Dns || !host.Contains('.', StringComparison.Ordinal) || IPAddress.TryParse(host, out _))
            return UrlInvalid;

        return LinkPlatforms.IsKnown(platform) && !LinkPlatforms.AllowsHost(platform!, host) ? HostMismatch : null;
    }

    private static string? LabelProblem(string? platform, string? label)
    {
        if (platform != LinkPlatforms.Other) return label is null || !LinkPlatforms.IsKnown(platform) ? null : LabelNotAllowed;
        if (label is null) return LabelRequired;
        if (label.Length is < MinLabelLength or > MaxLabelLength || !TextRules.IsOneCleanLine(label)) return LabelInvalid;
        return null;
    }
}

/// <summary>The writer's title (SPEC F14, "المسمى"): optional, one line, at most <see cref="MaxLength"/> characters.</summary>
public static class HeadlineRules
{
    public const int MaxLength = 120;

    public const string TooLong = "profile.headline_too_long";
    public const string Invalid = "profile.headline_invalid";

    /// <summary>Trimmed; empty or only spaces → null.</summary>
    public static string? Normalize(string? headline) => string.IsNullOrWhiteSpace(headline) ? null : headline.Trim();

    /// <summary>The validation code a (normalized) title breaks, or null.</summary>
    public static string? Problem(string? normalized) => normalized switch
    {
        null => null,
        { Length: > MaxLength } => TooLong,
        _ when !TextRules.IsOneCleanLine(normalized) => Invalid,
        _ => null,
    };
}

/// <summary>Shared checks for short one-line texts shown next to a name (titles, link labels; SPEC §14.2).</summary>
public static class TextRules
{
    /// <summary>
    /// No line breaks, tabs or other control characters (U+0000–U+001F, U+007F–U+009F), no direction marks or overrides
    /// (U+200E/U+200F, U+202A–U+202E) and no isolates (U+2066–U+2069): the clients isolate the text themselves.
    /// </summary>
    public static bool IsOneCleanLine(string text) =>
        !text.Any(IsForbidden);

    private static bool IsForbidden(char c) =>
        char.IsControl(c) || (int)c is 0x2028 or 0x2029 or 0x200E or 0x200F or (>= 0x202A and <= 0x202E) or (>= 0x2066 and <= 0x2069);
}
