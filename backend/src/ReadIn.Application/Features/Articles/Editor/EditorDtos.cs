using System.Text.Json;
using ReadIn.Application.Features.Uploads;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>
/// Everything the editor edits (F05), sent whole on every autosave and stored as the working copy's JSON. RDoc content
/// and the cover are kept in their stored form (<c>rdoc-asset://</c> / relative upload paths) and turned into public
/// URLs only in responses (ADR 0010).
/// </summary>
public sealed record ArticleDraftDocument
{
    public string SourceLanguage { get; init; } = default!;
    public IReadOnlyList<DraftTranslation> Translations { get; init; } = [];
    public Guid? FieldId { get; init; }
    public Guid? TopicId { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = [];
    public IReadOnlyList<SourceDto> Sources { get; init; } = [];
    public string? CoverUrl { get; init; }
    public string? VersionBadge { get; init; }
    public bool IsAiAssisted { get; init; }
    public IReadOnlyList<DraftAttachment> Attachments { get; init; } = [];
}

/// <param name="Content">RDoc (shared/rdoc/rdoc.schema.json); in a draft it may still fail the schema (e.g. empty alt).</param>
public sealed record DraftTranslation(string Language, string Title, string? Subtitle, JsonElement Content);

/// <summary>An attachment of the working copy: the same item as the former attachments request (ADR 0011).</summary>
public sealed record DraftAttachment(Guid MediaAssetId, int Order, string? Caption, string? AltText, string? Title, bool? AllowDownload);

public sealed record ArticleEditDto(
    Guid Id,
    string Status,
    string? Slug,
    DateTime? PublishedAt,
    int Version,
    DateTime SavedAt,
    bool HasUnpublishedChanges,
    ArticleDraftDocument Document,
    IReadOnlyList<MediaAssetDto> Media,
    DraftChecksDto Checks);

public sealed record DraftChecksDto(IReadOnlyList<DraftReadingTimeDto> ReadingTime, IReadOnlyList<DraftProblemDto> Problems);

public sealed record DraftReadingTimeDto(string Language, int Minutes, int Words);

/// <param name="Code">A stable error code; publishing fails with the first one.</param>
/// <param name="Tag">The tag name (as in the document) of a <c>tag.hidden</c> or <c>tag.limit</c> problem (SPEC F32).</param>
public sealed record DraftProblemDto(string Code, string? Language = null, string? BlockId = null, Guid? MediaAssetId = null, string? Tag = null);

public sealed record PublishedArticleDto(Guid Id, string Slug, DateTime PublishedAt, int Revision, bool FirstPublish);

public record ArticleRevisionDto(int Number, DateTime CreatedAt, string Title, IReadOnlyList<string> Languages);

/// <param name="Media">The attachments' assets, so the preview shows them like the reader does.</param>
public sealed record ArticleRevisionDetailsDto(
    int Number, DateTime CreatedAt, string Title, IReadOnlyList<string> Languages, ArticleDraftDocument Document, IReadOnlyList<MediaAssetDto> Media)
    : ArticleRevisionDto(Number, CreatedAt, Title, Languages);

public sealed record MyArticleDto(
    Guid Id,
    string Status,
    string? Slug,
    string Language,
    string Title,
    string? CoverUrl,
    FieldRefDto? Field,
    int ReadingTimeMinutes,
    DateTime SavedAt,
    DateTime? PublishedAt,
    bool HasUnpublishedChanges,
    int ReactionCount,
    int CommentCount,
    int ReadCount);

/// <summary>
/// A tag in the editor's suggestions (<c>GET /tags?q=</c>) and the tag page's header (<c>GET /tags/{slug}</c>), SPEC F32.
/// <see cref="ArticleCount"/>: published articles readers can see (not hidden by moderators, not deleted).
/// </summary>
public sealed record TagDto(string Slug, string Name, int ArticleCount);
