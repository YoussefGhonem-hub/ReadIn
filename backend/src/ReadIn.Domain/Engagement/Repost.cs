using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A member reposted an article (SPEC F29): it shows on their profile's Reposts tab and in their followers' Following
/// feed, labeled "أعاد نشره {name}". One per user per article (unique (UserId, ArticleId)); never your own article.
/// </summary>
public sealed class Repost : AggregateRoot
{
    /// <summary>The longest <see cref="Caption"/>, counted after <see cref="NormalizeCaption"/>.</summary>
    public const int MaxCaptionLength = 500;

    private Repost() { } // EF

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }

    /// <summary>When it was reposted: where it places the article in the Following feed and on the Reposts tab.</summary>
    public DateTime CreatedAt { get; private set; }

    /// <summary>
    /// The reposter's thoughts on the article ("repost with your thoughts"): plain text, not RDoc, shown under the label.
    /// Null when there are none. Always normalized (<see cref="NormalizeCaption"/>).
    /// </summary>
    public string? Caption { get; private set; }

    // Read-side navigation for query projections only.
    public Users.User User { get; private set; } = default!;

    /// <summary>A new repost, with an optional caption (null or blank: none). Raises the event that counts it and tells the author.</summary>
    public static Result<Repost> Create(Guid userId, Guid articleId, string? caption, DateTime now)
    {
        var normalized = NormalizeCaption(caption);
        if (CaptionProblem(normalized) is { } error) return error;

        var repost = new Repost { UserId = userId, ArticleId = articleId, CreatedAt = now, Caption = normalized };
        repost.Raise(() => new RepostChangedDomainEvent(articleId, userId, IsReposted: true) { OccurredAt = now });
        return repost;
    }

    /// <summary>
    /// Sets the caption of this repost: blank clears it. The repost keeps its time, and nothing is raised: the count doesn't
    /// move and the author isn't told again. Fails with <c>caption: ["repost.caption_too_long"]</c>; nothing changes then.
    /// </summary>
    public Result SetCaption(string caption)
    {
        var normalized = NormalizeCaption(caption);
        if (CaptionProblem(normalized) is { } error) return error;
        Caption = normalized;
        return Result.Success();
    }

    /// <summary>Call before deleting the row, so the article's repost count is recomputed after the commit.</summary>
    public void Remove() => Raise(() => new RepostChangedDomainEvent(ArticleId, UserId, IsReposted: false));

    /// <summary>
    /// Line breaks unified (<c>\r\n</c> and a lone <c>\r</c> become <c>\n</c>), then trimmed; empty or only spaces → null.
    /// The text itself is kept as is: it is plain text, never markup.
    /// </summary>
    public static string? NormalizeCaption(string? caption)
    {
        if (string.IsNullOrWhiteSpace(caption)) return null;
        return caption.Replace("\r\n", "\n", StringComparison.Ordinal).Replace('\r', '\n').Trim();
    }

    /// <summary>Whether a caption (raw or normalized) fits once normalized.</summary>
    public static bool CaptionFits(string? caption) => NormalizeCaption(caption) is not { Length: > MaxCaptionLength };

    private static Error? CaptionProblem(string? normalized) => normalized is { Length: > MaxCaptionLength }
        ? Error.Validation("validation.failed", "Validation failed.") with
        {
            Details = new Dictionary<string, string[]> { ["caption"] = [RepostErrors.CaptionTooLongCode] },
        }
        : null;
}

/// <summary>An article was reposted or the repost undone: its count follows (F27), and a new repost tells the author (F17).</summary>
public sealed record RepostChangedDomainEvent(Guid ArticleId, Guid UserId, bool IsReposted) : DomainEvent;

public static class RepostErrors
{
    public static readonly Error OwnArticle = Error.Validation("repost.own_article", "You can't repost your own article.");

    /// <summary>The validation code (in <c>validation.failed</c> → <c>caption</c>) of a caption over 500 characters after trimming.</summary>
    public const string CaptionTooLongCode = "repost.caption_too_long";
}
