using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.Highlights;

// F30 Highlights (SPEC F30, contract "Highlights (F30)"). Offsets are UTF-16 code units in the block's plain text
// (shared/rdoc/highlight-fixtures.json): startOffset inclusive, endOffset exclusive, and Text is exactly that slice.

/// <summary>
/// GET /articles/{id}/highlights?lang=: the reader's marks for one language version. <see cref="Language"/> is the
/// version they belong to (an unknown or missing <c>lang</c> gives the source language, as in the reader).
/// <see cref="Mine"/> is empty for guests; <see cref="Popular"/> never says who marked what.
/// </summary>
public sealed record ArticleHighlightsDto(
    Guid ArticleId,
    string Language,
    IReadOnlyList<HighlightDto> Mine,
    IReadOnlyList<PopularHighlightDto> Popular);

/// <summary>One of your highlights. Only ever sent to its owner.</summary>
public sealed record HighlightDto(Guid Id, string BlockId, int StartOffset, int EndOffset, string Text, DateTime CreatedAt);

/// <summary>
/// A range at least 3 readers marked exactly (same block, offsets and text), not counting writers the viewer muted.
/// <see cref="Count"/> is those readers, the viewer included when they marked it too.
/// </summary>
public sealed record PopularHighlightDto(string BlockId, int StartOffset, int EndOffset, string Text, int Count);

/// <summary>
/// POST /articles/{id}/highlights. A range that overlaps or touches your own highlights in the same block joins them:
/// <see cref="Highlight"/> is the one highlight left and <see cref="ReplacedIds"/> the ids it replaced (drop them).
/// </summary>
public sealed record HighlightCreatedDto(HighlightDto Highlight, IReadOnlyList<Guid> ReplacedIds);

/// <summary>
/// GET /me/highlights: one article version with all your highlights on it, newest first. Groups come newest first by
/// <see cref="LatestAt"/> (their newest highlight).
/// </summary>
public sealed record HighlightGroupDto(HighlightArticleDto Article, IReadOnlyList<HighlightDto> Highlights, DateTime LatestAt);

/// <summary>The article a group belongs to: open <c>/articles/{slug}?lang={language}</c> at the highlight's block.</summary>
/// <param name="Author">Null when the author deleted their account ("Deleted user").</param>
public sealed record HighlightArticleDto(Guid Id, string Slug, string Language, string Title, AuthorDto? Author);
