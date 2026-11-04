using System.Text.Json.Serialization;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Notifications;

/// <summary>
/// One entry of the notification center (SPEC F17, docs/api/contract-v1.md). Clients build the text from
/// <see cref="Type"/>, <see cref="Actor"/> and <see cref="ActorCount"/> ("Ahmed and 9 others commented on your article");
/// a null actor on an actor-based type is "Deleted user".
/// </summary>
/// <param name="Type">One of <see cref="NotificationTypes"/>.</param>
/// <param name="Actor">The latest actor; null for types without one, or when every actor deleted their account.</param>
/// <param name="ActorCount">Distinct actors (0 for types without one).</param>
/// <param name="Article">In the viewer's article language when that version exists, otherwise the source language.</param>
/// <param name="Link">The deep link to open (<c>readin://…</c>), the same as the push's <c>data.link</c>.</param>
public sealed record NotificationDto(
    Guid Id,
    string Type,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    bool IsRead,
    NotificationActorDto? Actor,
    int ActorCount,
    NotificationArticleDto? Article,
    NotificationCommentDto? Comment,
    NotificationDataDto Data,
    string Link);

public sealed record NotificationActorDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified);

/// <param name="Language"><c>ar-EG</c> | <c>en</c>: the version <see cref="Title"/> comes from.</param>
public sealed record NotificationArticleDto(Guid Id, string Slug, string Title, string Language);

/// <param name="Excerpt">Plain text on one line, at most <see cref="NotificationExcerpt.MaxLength"/> characters.</param>
public sealed record NotificationCommentDto(Guid Id, Guid? ParentId, string Excerpt);

/// <summary>Type-specific values; only the ones that apply are sent.</summary>
/// <param name="Threshold"><c>reactions_milestone</c>: 10, 50 or 100.</param>
/// <param name="StreakDays"><c>streak_reminder</c>: the streak the user keeps by reading today.</param>
/// <param name="SecurityChange"><c>security_alert</c>: what changed.</param>
public sealed record NotificationDataDto(
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? Threshold,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? StreakDays,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] SecurityChange? SecurityChange);

/// <summary>GET /me/notifications/unread-count: the badge without the Realtime Database.</summary>
public sealed record UnreadNotificationsDto(int Unread);

/// <summary>Settings → Notifications (SPEC F17).</summary>
/// <param name="Types">Every configurable type with its mode (GET); on PUT only the types to change.</param>
public sealed record NotificationSettingsDto(QuietHoursDto QuietHours, IReadOnlyDictionary<string, NotificationMode> Types);

/// <param name="Start"><c>HH:mm</c> in the user's time zone.</param>
/// <param name="End"><c>HH:mm</c>, exclusive; before <see cref="Start"/> when the window spans midnight.</param>
public sealed record QuietHoursDto(bool Enabled, string Start, string End);
