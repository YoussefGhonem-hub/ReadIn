using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A reader marked text in one block of one language version of an article (SPEC F30). The range is
/// [<see cref="StartOffset"/>, <see cref="EndOffset"/>) in UTF-16 code units of the block's plain text, and
/// <see cref="Text"/> is that slice when it was made: after the author updates the block, a highlight whose text is no
/// longer there is not shown. Private to its owner; others only ever see anonymous counts of identical ranges.
/// </summary>
public sealed class ArticleHighlight : Entity
{
    public const int MinLength = 3;
    public const int MaxLength = 1000;

    /// <summary>Highlights per user per article, both language versions together.</summary>
    public const int MaxPerArticle = 100;

    public const int MaxBlockIdLength = 64;

    private ArticleHighlight() { } // EF

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }

    /// <summary>The version it belongs to: <c>ar-EG</c> or <c>en</c>.</summary>
    public string Language { get; private set; } = default!;

    public string BlockId { get; private set; } = default!;
    public int StartOffset { get; private set; }
    public int EndOffset { get; private set; }
    public string Text { get; private set; } = default!;
    public DateTime CreatedAt { get; private set; }

    /// <summary>The caller has checked the range against the block's current plain text.</summary>
    public static ArticleHighlight Create(
        Guid userId, Guid articleId, string language, string blockId, int startOffset, int endOffset, string text, DateTime now) => new()
        {
            UserId = userId,
            ArticleId = articleId,
            Language = language,
            BlockId = blockId,
            StartOffset = startOffset,
            EndOffset = endOffset,
            Text = text,
            CreatedAt = now,
        };
}

public static class HighlightErrors
{
    public static readonly Error TextMismatch =
        Error.Validation("highlight.text_mismatch", "This text isn't at these offsets in the article's current version.");
    public static readonly Error BlockNotAllowed = Error.Validation("highlight.block_not_allowed", "This block can't be highlighted.");
    public static readonly Error TooShort = Error.Validation("highlight.too_short", "A highlight has at least 3 characters.");
    public static readonly Error TooLong = Error.Validation("highlight.too_long", "A highlight has at most 1,000 characters.");
    public static readonly Error Limit = Error.Validation("highlight.limit", "You can have at most 100 highlights in one article.");
    public static readonly Error NotFound = Error.NotFound("highlight.not_found", "Highlight not found.");
}
