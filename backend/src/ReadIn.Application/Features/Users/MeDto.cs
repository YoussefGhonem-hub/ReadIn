using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users;

public sealed record UserLinksDto(string? GitHub, string? LinkedIn, string? Website);

public sealed record InterestsDto(IReadOnlyList<Guid> FieldIds, IReadOnlyList<Guid> TopicIds);

public sealed record MeDto
{
    public Guid Id { get; init; }
    public string Email { get; init; } = default!;
    public string DisplayName { get; init; } = default!;
    public string Username { get; init; } = default!;
    public string? AvatarUrl { get; init; }
    public string? Bio { get; init; }
    public UserLinksDto Links { get; init; } = new(null, null, null);
    public string UiLanguage { get; init; } = default!;
    public string ArticleLanguage { get; init; } = default!;
    public ThemePreference Theme { get; init; }
    public string TimeZone { get; init; } = default!;
    public string ReminderTime { get; init; } = default!;
    public bool IsVerified { get; init; }
    public bool OnboardingCompleted { get; init; }
    public IReadOnlyList<string> Roles { get; init; } = [];
    public IReadOnlyList<string> Permissions { get; init; } = [];
    public InterestsDto Interests { get; init; } = new([], []);
}
