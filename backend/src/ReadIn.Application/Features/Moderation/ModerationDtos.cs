using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Moderation;

/// <summary>GET /moderation/summary: targets with open reports, for the nav badge.</summary>
public sealed record ModerationSummaryDto(OpenReportCountsDto Open);

public sealed record OpenReportCountsDto(int Article, int Comment, int User, int Total);

/// <summary>One target in the queue, with its reports in <see cref="Status"/> (SPEC F22).</summary>
/// <param name="Reasons">Reports per reason (<c>spam</c>, <c>misinformation</c>…); reasons nobody picked are left out.</param>
/// <param name="ClosedAt">When the last of these reports was resolved or dismissed; null in the open list.</param>
public sealed record ModerationQueueItemDto(
    ReportTargetType TargetType,
    Guid TargetId,
    ReportStatus Status,
    int ReportCount,
    IReadOnlyDictionary<string, int> Reasons,
    DateTime FirstReportedAt,
    DateTime LastReportedAt,
    DateTime? ClosedAt,
    ModerationTargetDto Target);

/// <summary>
/// The reported target as moderators see it. Articles fill <see cref="Title"/>, <see cref="Slug"/> and
/// <see cref="Language"/>; comments <see cref="Body"/> and the article fields; users <see cref="SuspendedUntil"/> and
/// <see cref="WarningCount"/>. The other fields are null.
/// </summary>
public sealed record ModerationTargetDto
{
    /// <summary>One of <see cref="ModerationTargetStates"/>.</summary>
    public string State { get; init; } = default!;

    /// <summary>The article's or comment's author, or the user target itself; null once deleted.</summary>
    public AuthorDto? Author { get; init; }

    public string? Title { get; init; }
    public string? Slug { get; init; }
    public string? Language { get; init; }

    public string? Body { get; init; }
    public Guid? ArticleId { get; init; }
    public string? ArticleSlug { get; init; }
    public string? ArticleTitle { get; init; }

    /// <summary>While suspended: when it ends; null = permanent.</summary>
    public DateTime? SuspendedUntil { get; init; }

    /// <summary>Warnings this user got so far.</summary>
    public int? WarningCount { get; init; }
}

public static class ModerationTargetStates
{
    public const string Visible = "visible";
    public const string Hidden = "hidden";
    public const string Deleted = "deleted";
    public const string Active = "active";
    public const string Suspended = "suspended";
}

/// <param name="Reporter">Null once the reporter deleted their account.</param>
/// <param name="ClosedBy">The moderator who resolved or dismissed it.</param>
public sealed record ModerationReportDto(
    Guid Id,
    UserSummaryDto? Reporter,
    ReportReason Reason,
    string? Details,
    ReportStatus Status,
    DateTime CreatedAt,
    DateTime? ClosedAt,
    UserSummaryDto? ClosedBy);

/// <param name="Item">Status open when any report is open, else the latest closed status.</param>
/// <param name="Reports">Every report on the target, newest first.</param>
/// <param name="History">Actions on the target and, for an article or comment, on its author's account; newest first.</param>
/// <param name="Categories">
/// A user target's writer categories (SPEC F31), all of them in the writer's order, empty ones included, for "clear the
/// name" (<c>clear_category</c>); empty for article and comment targets.
/// </param>
public sealed record ModerationCaseDto(
    ModerationQueueItemDto Item,
    IReadOnlyList<ModerationReportDto> Reports,
    IReadOnlyList<ModerationActionDto> History,
    IReadOnlyList<WriterCategoryDto> Categories);

/// <summary>One row of the moderation log (<c>ModerationActions</c>).</summary>
/// <param name="Action">One of <see cref="ModerationActionTypes"/>.</param>
/// <param name="TargetUser">The affected user (author or user target); null once deleted.</param>
/// <param name="Moderator">Null once the moderator deleted their account.</param>
public sealed record ModerationActionDto(
    Guid Id,
    string Action,
    ReportTargetType TargetType,
    Guid TargetId,
    string? TargetLabel,
    UserSummaryDto? TargetUser,
    UserSummaryDto? Moderator,
    string? Note,
    DateTime? SuspendedUntil,
    int ReportsClosed,
    DateTime CreatedAt);

/// <summary>A warning or a hidden article the user still has to acknowledge.</summary>
/// <param name="Kind">One of <see cref="NoticeKinds"/>.</param>
/// <param name="Article">The hidden article (<c>article_hidden</c>); null for a warning.</param>
public sealed record ModerationNoticeDto(Guid Id, string Kind, string? Note, NoticeArticleDto? Article, DateTime CreatedAt);

public sealed record NoticeArticleDto(Guid Id, string Slug, string Title);

public sealed record ModerationNoticesDto(IReadOnlyList<ModerationNoticeDto> Items);
