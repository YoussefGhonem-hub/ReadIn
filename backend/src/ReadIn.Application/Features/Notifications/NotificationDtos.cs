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
/// <param name="Approved"><c>verification_result</c> (F19): approved (true) or rejected (false).</param>
/// <param name="ArticleCount">
/// The official @readin account's day entry (<c>followed_writer_article</c>): how many of its new articles it holds (≥ 1);
/// from 2 the text is "ReadIn published {n} new articles" and the link the account's profile.
/// </param>
/// <param name="AnnouncementId"><c>announcement</c> (F23): the announcement.</param>
/// <param name="Title"><c>announcement</c>: its title in the request's UI language.</param>
/// <param name="Body"><c>announcement</c>: its text in the request's UI language.</param>
/// <param name="TicketId"><c>support_reply</c>, <c>support_ticket</c> (F35): the ticket.</param>
/// <param name="TicketNumber">The ticket's number ("#12").</param>
/// <param name="Subject">The ticket's subject.</param>
/// <param name="Closed"><c>support_reply</c>: true when support closed the ticket.</param>
/// <param name="TargetType"><c>report_new</c>, <c>report_resolved</c> (F22): <c>article</c> | <c>comment</c> | <c>user</c> | <c>repost</c>.</param>
/// <param name="TargetId"><c>report_new</c>: the reported target.</param>
/// <param name="TargetLabel">The target's title, the comment's first 80 characters, <c>@username</c> or the caption.</param>
/// <param name="ReportCount"><c>report_new</c>: open reports on the target.</param>
/// <param name="System"><c>report_new</c>: filed by the content filter (F37).</param>
/// <param name="Outcome"><c>report_resolved</c>: <c>actioned</c> | <c>no_violation</c>.</param>
public sealed record NotificationDataDto(
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? Threshold,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? StreakDays,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] SecurityChange? SecurityChange,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] bool? Approved = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? ArticleCount = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] Guid? AnnouncementId = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Title = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Body = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] Guid? TicketId = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? TicketNumber = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Subject = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] bool? Closed = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? TargetType = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] Guid? TargetId = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? TargetLabel = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] int? ReportCount = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] bool? System = null,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Outcome = null);

/// <summary>GET /me/notifications/unread-count: the badge without the Realtime Database.</summary>
public sealed record UnreadNotificationsDto(int Unread);

/// <summary>Settings → Notifications (SPEC F17).</summary>
/// <param name="Types">Every configurable type with its mode (GET); on PUT only the types to change.</param>
public sealed record NotificationSettingsDto(QuietHoursDto QuietHours, IReadOnlyDictionary<string, NotificationMode> Types);

/// <param name="Start"><c>HH:mm</c> in the user's time zone.</param>
/// <param name="End"><c>HH:mm</c>, exclusive; before <see cref="Start"/> when the window spans midnight.</param>
public sealed record QuietHoursDto(bool Enabled, string Start, string End);
