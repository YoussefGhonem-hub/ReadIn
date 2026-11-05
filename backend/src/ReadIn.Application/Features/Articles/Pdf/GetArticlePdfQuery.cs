using System.Text.Json;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Pdf;

/// <summary>
/// <c>GET /articles/{id}/pdf?lang=</c> (SPEC F33): the author's own published or archived article, its published version
/// in <paramref name="Language"/> (a missing or unknown one gives the source language), as a PDF built in the request
/// and never stored.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.ExportPdf)]
public sealed record GetArticlePdfQuery(Guid ArticleId, string? Language) : IQuery<Result<ArticlePdfFile>>;

/// <param name="FileName"><c>{slug}-{lang}.pdf</c>; sent as RFC 5987 <c>filename*</c>, with <see cref="AsciiFileName"/> as the fallback.</param>
public sealed record ArticlePdfFile(string FileName, string Language, byte[] Content)
{
    public const string AsciiFileName = "readin-article.pdf";
}

internal sealed class GetArticlePdfQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    ArticlePdfImages images,
    IArticlePdfRenderer renderer)
    : IQueryHandler<GetArticlePdfQuery, Result<ArticlePdfFile>>
{
    public async ValueTask<Result<ArticlePdfFile>> Handle(GetArticlePdfQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        // Anyone but the author, a draft, and a deleted article (query filter) are all "not found".
        var article = await db.Articles.AsNoTracking()
            .Where(a => a.Id == query.ArticleId && a.AuthorId == userId && a.PublishedAt != null
                        && (a.Status == ArticleStatus.Published || a.Status == ArticleStatus.Archived))
            .Select(a => new
            {
                a.Id,
                a.Slug,
                a.SourceLanguage,
                a.HiddenAt,
                a.CoverUrl,
                a.IsAiAssisted,
                PublishedAt = a.PublishedAt!.Value,
                FieldNameAr = a.Field.NameAr,
                FieldNameEn = a.Field.NameEn,
                a.Field.IsSensitive,
                TopicNameAr = a.Topic == null ? null : a.Topic.NameAr,
                TopicNameEn = a.Topic == null ? null : a.Topic.NameEn,
                Languages = a.Translations.Select(t => t.Language).ToList(),
            })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;

        // The file carries the ReadIn logo, so a hidden article has none (SPEC F22).
        if (article.HiddenAt is not null) return ArticlePdfErrors.Hidden;

        var language = query.Language is { } requested && article.Languages.Contains(requested) ? requested : article.SourceLanguage;
        var translation = await db.ArticleTranslations.AsNoTracking()
            .Where(t => t.ArticleId == article.Id && t.Language == language)
            .Select(t => new { t.Title, t.Subtitle, t.ContentJson, t.ReadingTimeMinutes })
            .FirstOrDefaultAsync(cancellationToken);
        if (translation is null) return ArticleErrors.NotFound;

        var author = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new
            {
                u.DisplayName,
                u.Username,
                u.TimeZone,
                IsVerified = u.IsVerified,
            })
            .FirstAsync(cancellationToken);

        var tags = await db.Articles.AsNoTracking()
            .Where(a => a.Id == article.Id)
            .SelectMany(a => a.Tags)
            .Where(t => !t.Tag.IsHidden)
            .OrderBy(t => t.Position).ThenBy(t => t.TagId)
            .Select(t => t.Tag.Name)
            .ToListAsync(cancellationToken);

        var sources = await db.Articles.AsNoTracking()
            .Where(a => a.Id == article.Id)
            .SelectMany(a => a.Sources)
            .OrderBy(s => s.SortOrder)
            .Select(s => new ArticlePdfSource(s.Title, s.Url))
            .ToListAsync(cancellationToken);

        var attachments = await db.ArticleAttachments.AsNoTracking()
            .Where(a => a.ArticleId == article.Id && a.MediaAsset.Status == MediaStatus.Ready)
            .OrderBy(a => a.Order)
            .Select(a => new { a.Caption, a.AltText, a.MediaAsset.Kind, a.MediaAsset.Variants, a.MediaAsset.Title, a.MediaAsset.PageCount })
            .ToListAsync(cancellationToken);

        using var content = JsonDocument.Parse(translation.ContentJson);
        var contentImages = new Dictionary<string, ArticlePdfImage>(StringComparer.Ordinal);
        foreach (var src in ArticlePdfImages.UploadSources(content.RootElement))
        {
            if (await images.LoadAsync(userId, src, ArticlePdfImages.ContentWidth, cancellationToken) is { } image)
                contentImages[src] = image;
        }

        var imageAttachments = new List<ArticlePdfImageAttachment>();
        foreach (var attachment in attachments.Where(a => a.Kind == MediaKind.Image))
        {
            var variant = attachment.Variants.Where(v => v.Width <= ArticlePdfImages.ContentWidth).OrderByDescending(v => v.Width).FirstOrDefault()
                          ?? attachment.Variants.OrderBy(v => v.Width).FirstOrDefault();
            if (variant is not null && await images.ReadAsync(variant.Path, cancellationToken) is { } image)
                imageAttachments.Add(new ArticlePdfImageAttachment(image, attachment.AltText ?? string.Empty, attachment.Caption));
        }

        var document = attachments.FirstOrDefault(a => a.Kind == MediaKind.Document) is { } pdf
            ? new ArticlePdfDocumentAttachment(pdf.Title ?? string.Empty, pdf.PageCount ?? 0)
            : null;

        var arabic = language == ArticleLanguages.EgyptianArabic;
        var result = await renderer.RenderAsync(new ArticlePdfDocument
        {
            ArticleId = article.Id,
            Language = language,
            Slug = article.Slug,
            Title = translation.Title,
            Subtitle = translation.Subtitle,
            Author = new ArticlePdfAuthor(author.DisplayName, author.Username, author.IsVerified),
            PublishedOn = LocalDate(article.PublishedAt, author.TimeZone),
            ReadingTimeMinutes = translation.ReadingTimeMinutes,
            FieldName = arabic ? article.FieldNameAr : article.FieldNameEn,
            TopicName = arabic ? article.TopicNameAr : article.TopicNameEn,
            Tags = tags,
            ShowHealthDisclaimer = article.IsSensitive,
            IsAiAssisted = article.IsAiAssisted,
            Cover = await images.LoadAsync(userId, article.CoverUrl, ArticlePdfImages.CoverWidth, cancellationToken),
            Content = content.RootElement.Clone(),
            Images = contentImages,
            Sources = sources,
            ImageAttachments = imageAttachments,
            DocumentAttachment = document,
        }, cancellationToken);

        return result.IsSuccess
            ? new ArticlePdfFile($"{article.Slug}-{language}.pdf", language, result.Value)
            : result.Error;
    }

    /// <summary>The publish date as the writer saw it; UTC when their time zone is unknown here.</summary>
    private static DateOnly LocalDate(DateTime utc, string timeZone)
    {
        try
        {
            return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utc, DateTimeKind.Utc), TimeZoneInfo.FindSystemTimeZoneById(timeZone)));
        }
        catch (Exception e) when (e is TimeZoneNotFoundException or InvalidTimeZoneException)
        {
            return DateOnly.FromDateTime(utc);
        }
    }
}
