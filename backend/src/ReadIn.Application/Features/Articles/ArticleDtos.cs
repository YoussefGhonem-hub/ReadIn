using System.Text.Json;
using System.Text.Json.Serialization;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Articles;

/// <summary>
/// A writer as cards, the reader, comments and lists show them. <see cref="Headline"/> is their current title (SPEC F14),
/// shown on one line under the name; null when they have none.
/// </summary>
public sealed record AuthorDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified, string? Headline);

/// <summary>Reactions per type (SPEC F10); the same shape as <c>/live/articles/{id}/reactions</c> (F27).</summary>
public sealed record ReactionCountsDto(int Insightful, int Love, int Fire, int MindBlown)
{
    public static readonly ReactionCountsDto None = new(0, 0, 0, 0);

    public int Total() => Insightful + Love + Fire + MindBlown;
}

/// <summary>
/// A field (or topic) on a card. <see cref="IsSensitive"/>: readers show the health disclaimer (SPEC F04); a topic
/// carries its field's flag.
/// </summary>
public sealed record FieldRefDto(Guid Id, string Slug, string Name, string NameAr, string NameEn, bool IsSensitive);

public sealed record SourceDto(string Title, string Url);

/// <summary>
/// A tag on a card or in the reader (SPEC F32): <see cref="Name"/> is shown as <c>#name</c>, <see cref="Slug"/> opens the
/// tag page (<c>/tags/{slug}</c>). Hidden tags are never carried.
/// </summary>
public sealed record TagRefDto(string Slug, string Name);

/// <summary>
/// The writer's category of an article in the reader (SPEC F31): "في قسم {name}", linking to
/// <c>/@{author.username}/c/{slug}</c>.
/// </summary>
public sealed record WriterCategoryRefDto(string Slug, string Name);

public record ArticleCardDto
{
    /// <summary>Tags a card carries (SPEC F34); <see cref="TagCount"/> gives the rest as "+N".</summary>
    public const int MaxCardTags = 3;

    public Guid Id { get; init; }
    public string Slug { get; init; } = default!;

    /// <summary>The language actually served (requested language, or the source language as fallback).</summary>
    public string Language { get; init; } = default!;

    public string Title { get; init; } = default!;
    public string? Subtitle { get; init; }

    /// <summary>
    /// The served version's beginning as plain text (SPEC F34): at most 400 characters, cut at a word, lines separated by
    /// <c>\n</c>. Null only for a version published before excerpts existed and not backfilled yet.
    /// </summary>
    public string? Excerpt { get; init; }

    /// <summary>The article holds more than <see cref="Excerpt"/> (cut text, later blocks, or blocks it skips); true when the excerpt is null.</summary>
    public bool HasMore { get; init; }

    public string? CoverUrl { get; init; }
    public FieldRefDto Field { get; init; } = default!;

    /// <summary>The article's topic, if it has one (on cards since F28: the "كتم المواضيع" sheet shows it).</summary>
    public FieldRefDto? Topic { get; init; }

    /// <summary>Null when the author deleted their account; clients show "Deleted user" (SPEC §9.6).</summary>
    public AuthorDto? Author { get; init; }
    public int ReadingTimeMinutes { get; init; }
    public bool IsAiAssisted { get; init; }
    public string? VersionBadge { get; init; }
    public DateTime? PublishedAt { get; init; }

    /// <summary>
    /// The article's visible tags in the writer's order (SPEC F32): the first <see cref="MaxCardTags"/> on cards (F34), all
    /// of them in <see cref="ArticleDetailsDto"/>.
    /// </summary>
    public IReadOnlyList<TagRefDto> Tags { get; init; } = [];

    /// <summary>All the article's visible tags (at most 5), for the card's "+N".</summary>
    public int TagCount { get; init; }

    /// <summary>All reactions; always the sum of <see cref="Reactions"/>.</summary>
    public int ReactionCount { get; init; }

    public ReactionCountsDto Reactions { get; init; } = ReactionCountsDto.None;
    public int CommentCount { get; init; }
    public int SaveCount { get; init; }

    /// <summary>People who reposted it (SPEC F29): the number beside the Repost icon.</summary>
    public int RepostCount { get; init; }

    /// <summary>The viewer's reaction; null for guests. Loaded after the projection by <see cref="ArticleViewerStateReader"/>.</summary>
    public ReactionType? MyReaction { get; init; }

    /// <summary>The viewer saved it; false for guests.</summary>
    public bool IsSaved { get; init; }

    /// <summary>The viewer reposted it (SPEC F29); false for guests.</summary>
    public bool IsReposted { get; init; }

    /// <summary>
    /// The label "أعاد نشره {name}" (SPEC F29, F34): set on Following-feed cards a repost placed and on a profile's Reposts
    /// tab; null everywhere else.
    /// </summary>
    public Reposts.RepostLabelDto? RepostedBy { get; init; }

    /// <summary>The viewer follows the author; false for guests, on your own articles and for a deleted author.</summary>
    public bool IsFollowingAuthor { get; init; }

    /// <summary>
    /// The viewer muted the author (SPEC F28): the reader's "انت كاتم الكاتب ده" banner. False for guests, on your own
    /// articles and for a deleted author. Lists that apply mutes never carry such a card.
    /// </summary>
    public bool IsAuthorMuted { get; init; }

    /// <summary>The viewer muted the article's field (the "كتم المواضيع" sheet's toggle); false for guests.</summary>
    public bool IsFieldMuted { get; init; }

    /// <summary>The viewer muted the article's topic; false for guests and without a topic.</summary>
    public bool IsTopicMuted { get; init; }

    /// <summary>1–10 images or one PDF (ADR 0011). Loaded after the projection by <see cref="ArticleAttachmentsReader"/>.</summary>
    public ArticleAttachmentsDto? Attachments { get; init; }
}

public sealed record ImageAttachmentDto(
    Guid AssetId,
    int Order,
    string? Caption,
    string AltText,
    int Width,
    int Height,
    string? BlurHash,
    IReadOnlyList<Uploads.MediaVariantDto> Variants);

public sealed record DocumentAttachmentDto(
    Guid AssetId,
    string Title,
    int PageCount,
    bool AllowDownload,
    bool CanDownload,
    string DownloadUrl,
    IReadOnlyList<Uploads.MediaPageDto> Pages);

/// <summary><see cref="Kind"/> is <c>images</c> or <c>document</c>; never both.</summary>
public sealed record ArticleAttachmentsDto(string Kind, IReadOnlyList<ImageAttachmentDto> Images, DocumentAttachmentDto? Document)
{
    public const string ImagesKind = "images";
    public const string DocumentKind = "document";
}

/// <summary><see cref="Note"/> is the latest hide's note to the author (null when the moderator wrote none).</summary>
public sealed record ArticleModerationDto(DateTime HiddenAt, string? Note);

public sealed record ArticleDetailsDto : ArticleCardDto
{
    public IReadOnlyList<string> AvailableLanguages { get; init; } = [];
    public string? Summary { get; init; }

    /// <summary>RDoc document (shared/rdoc/rdoc.schema.json).</summary>
    public JsonElement Content { get; init; }

    public IReadOnlyList<SourceDto> Sources { get; init; } = [];
    public int ReadCount { get; init; }

    /// <summary>The viewer's collections that hold this article; empty for guests and unsaved articles.</summary>
    public IReadOnlyList<Guid> CollectionIds { get; init; } = [];

    /// <summary>The viewer's reading progress, so the reader can resume (F04); null for guests and unopened articles.</summary>
    public MyProgressDto? MyProgress { get; init; }
    /// <summary>Set only while a moderator hides the article (SPEC F22); then only its author and moderators open it.</summary>
    public ArticleModerationDto? Moderation { get; init; }

    /// <summary>The writer's category of the article (SPEC F31); null when it has none.</summary>
    public WriterCategoryRefDto? Category { get; init; }

    /// <summary>Raw RDoc from the projection; parsed into <see cref="Content"/> by the handler.</summary>
    [JsonIgnore]
    public string ContentJson { get; init; } = default!;
}

/// <summary>
/// GET /articles/{id}/preview (SPEC F34): what "Read more" shows in a feed card. <see cref="Content"/> is an RDoc document
/// with the article's first whole blocks, about 300 words; <see cref="IsComplete"/> says it is the whole article.
/// </summary>
public sealed record ArticlePreviewDto(Guid Id, string Language, JsonElement Content, bool IsComplete);

/// <summary>
/// Where the viewer left an article: <see cref="LastPosition"/> is what the reader sent (the scroll position as a
/// fraction, e.g. "0.4523") and <see cref="Language"/> the version it was measured on.
/// </summary>
public sealed record MyProgressDto(string Language, int Percent, string? LastPosition, DateTime? CompletedAt);
