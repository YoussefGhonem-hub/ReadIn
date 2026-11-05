using System.Text.Json;

namespace ReadIn.Application.Features.Articles.Pdf;

/// <summary>
/// Everything one article PDF shows (SPEC F33), gathered by <see cref="GetArticlePdfQueryHandler"/> from SQL and the
/// uploads folder, so the renderer never reads the database or the network. Labels in the file follow
/// <see cref="Language"/>, not the app language.
/// </summary>
public sealed record ArticlePdfDocument
{
    public required Guid ArticleId { get; init; }

    /// <summary><c>ar-EG</c> (RTL) or <c>en</c> (LTR): the printed version.</summary>
    public required string Language { get; init; }

    public required string Slug { get; init; }
    public required string Title { get; init; }
    public string? Subtitle { get; init; }

    public required ArticlePdfAuthor Author { get; init; }

    /// <summary>The first publish, as a date in the writer's time zone.</summary>
    public required DateOnly PublishedOn { get; init; }

    public required int ReadingTimeMinutes { get; init; }

    /// <summary>The field and topic names in the article's language.</summary>
    public required string FieldName { get; init; }
    public string? TopicName { get; init; }

    /// <summary>Visible tags in the writer's order.</summary>
    public IReadOnlyList<string> Tags { get; init; } = [];

    /// <summary>Medicine and Public Health (SPEC §20): the health disclaimer on the first page.</summary>
    public bool ShowHealthDisclaimer { get; init; }

    public bool IsAiAssisted { get; init; }

    /// <summary>The cover from the 1200 variant; null when there is none or it couldn't be read.</summary>
    public ArticlePdfImage? Cover { get; init; }

    /// <summary>The published RDoc of <see cref="Language"/>, as stored (<c>rdoc-asset://</c> image sources).</summary>
    public required JsonElement Content { get; init; }

    /// <summary>Image blocks' pictures by their RDoc <c>src</c>, from the 1600 variant. A block whose src isn't here (an external URL) prints as a card.</summary>
    public IReadOnlyDictionary<string, ArticlePdfImage> Images { get; init; } = new Dictionary<string, ArticlePdfImage>();

    public IReadOnlyList<ArticlePdfSource> Sources { get; init; } = [];

    public IReadOnlyList<ArticlePdfImageAttachment> ImageAttachments { get; init; } = [];

    public ArticlePdfDocumentAttachment? DocumentAttachment { get; init; }
}

/// <param name="Username">Links the name to the profile.</param>
public sealed record ArticlePdfAuthor(string DisplayName, string Username, bool IsVerified);

/// <summary>An image read from the uploads folder (WebP), inlined into the PDF; never fetched.</summary>
public sealed record ArticlePdfImage(byte[] Bytes, string MediaType);

public sealed record ArticlePdfSource(string Title, string Url);

public sealed record ArticlePdfImageAttachment(ArticlePdfImage Image, string AltText, string? Caption);

/// <summary>A PDF attachment prints as a card (its pages are never merged into the file).</summary>
public sealed record ArticlePdfDocumentAttachment(string Title, int PageCount);
