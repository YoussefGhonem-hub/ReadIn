using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

public sealed record InterestsDto(IReadOnlyList<Guid> FieldIds, IReadOnlyList<Guid> TopicIds);

/// <summary>A linked Google or Apple account, listed in Settings → Account (SPEC F18).</summary>
public sealed record ExternalLoginDto(string Provider, string? Email, DateTime LinkedAt);

/// <summary>Settings → Privacy (SPEC F18), changed with PUT /me/privacy.</summary>
/// <param name="PublicReadingStats">The reading stats card and heatmap are on the public profile (F14).</param>
/// <param name="WhoCanMention">Who may @mention the user in comments and articles: <c>everyone</c>, <c>following</c>, <c>nobody</c>.</param>
public sealed record PrivacyDto(bool PublicReadingStats, MentionPolicy WhoCanMention = MentionPolicy.Everyone);

/// <summary>The signed-in user. The only DTO that carries the phone number (SPEC §9.5).</summary>
public sealed record MeDto
{
    public Guid Id { get; init; }
    public string? PhoneNumber { get; init; }
    public string? Email { get; init; }
    public string DisplayName { get; init; } = default!;
    public string Username { get; init; } = default!;
    public string? AvatarUrl { get; init; }

    /// <summary>The title under the name (SPEC F14); null when empty.</summary>
    public string? Headline { get; init; }

    public string? Bio { get; init; }

    /// <summary>Social links (SPEC F14), in the user's order; empty when none.</summary>
    public IReadOnlyList<ProfileLinkDto> Links { get; init; } = [];
    public string UiLanguage { get; init; } = default!;
    public string ArticleLanguage { get; init; } = default!;
    public ThemePreference Theme { get; init; }
    public string TimeZone { get; init; } = default!;
    public string ReminderTime { get; init; } = default!;

    /// <summary>Highlight marks are shown in the reader (SPEC F30, F18); default on, changed with PUT /me/preferences.</summary>
    public bool ShowHighlights { get; init; } = true;

    public bool IsVerified { get; init; }
    public bool OnboardingCompleted { get; init; }

    /// <summary>Client guards, applied in this order after sign in (SPEC §9.2).</summary>
    public bool MustChangePassword { get; init; }
    public bool MustSetRecoveryPin { get; init; }
    public bool IsProfileComplete { get; init; }
    public bool HasRecoveryPin { get; init; }

    /// <summary>False for Google/Apple-only accounts: Settings offers "add phone sign in" instead of "change password".</summary>
    public bool HasPassword { get; init; }
    public IReadOnlyList<ExternalLoginDto> ExternalLogins { get; init; } = [];

    public IReadOnlyList<string> Roles { get; init; } = [];
    public IReadOnlyList<string> Permissions { get; init; } = [];
    public InterestsDto Interests { get; init; } = new([], []);
    public PrivacyDto Privacy { get; init; } = new(false);

    /// <summary>The Terms of Use version the account accepted (SPEC F37); null = none yet.</summary>
    public string? TermsVersion { get; init; }

    /// <summary>
    /// The account hasn't accepted the current version (<c>GET /legal</c>): show the terms screen, after the password and PIN
    /// guards (SPEC §9.2). The API doesn't refuse other calls for it.
    /// </summary>
    public bool MustAcceptTerms { get; init; }
}
