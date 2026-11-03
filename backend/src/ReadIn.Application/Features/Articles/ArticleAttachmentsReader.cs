using Mapster;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles;

/// <summary>
/// Loads the attachments of a page of articles in two queries (attachments, then document pages) and shapes them
/// into <see cref="ArticleAttachmentsDto"/> with absolute URLs (ADR 0011). Feed cards pass a page limit (first 10
/// page thumbs); the reader gets every page.
/// </summary>
public sealed class ArticleAttachmentsReader(IAppDbContext db, IFileStorage storage, IApiUrls urls, TypeAdapterConfig mapping)
{
    private sealed record Row(
        Guid ArticleId,
        Guid AssetId,
        int Order,
        string? Caption,
        string? AltText,
        MediaKind Kind,
        Guid OwnerId,
        int? Width,
        int? Height,
        string? BlurHash,
        IReadOnlyList<MediaVariant> Variants,
        string? Title,
        int? PageCount,
        bool AllowDownload);

    /// <param name="viewer">The caller, for <see cref="DocumentAttachmentDto.CanDownload"/>; null for cached, caller-independent results.</param>
    public async Task<IReadOnlyDictionary<Guid, ArticleAttachmentsDto>> LoadAsync(
        IReadOnlyCollection<Guid> articleIds, int? pageLimit, ICurrentUser? viewer, CancellationToken cancellationToken)
    {
        if (articleIds.Count == 0) return new Dictionary<Guid, ArticleAttachmentsDto>();

        var rows = await db.ArticleAttachments.AsNoTracking()
            .Where(a => articleIds.Contains(a.ArticleId) && a.MediaAsset.Status == MediaStatus.Ready)
            .OrderBy(a => a.Order)
            .Select(a => new Row(
                a.ArticleId, a.MediaAssetId, a.Order, a.Caption, a.AltText,
                a.MediaAsset.Kind, a.MediaAsset.OwnerId, a.MediaAsset.Width, a.MediaAsset.Height, a.MediaAsset.BlurHash,
                a.MediaAsset.Variants, a.MediaAsset.Title, a.MediaAsset.PageCount, a.MediaAsset.AllowDownload))
            .ToListAsync(cancellationToken);
        if (rows.Count == 0) return new Dictionary<Guid, ArticleAttachmentsDto>();

        var documentIds = rows.Where(r => r.Kind == MediaKind.Document).Select(r => r.AssetId).ToList();
        var limit = pageLimit ?? int.MaxValue;
        var pages = documentIds.Count == 0
            ? []
            : await db.MediaAssets.AsNoTracking()
                .Where(m => documentIds.Contains(m.Id))
                .SelectMany(m => m.Pages)
                .Where(p => p.PageNo <= limit)
                .OrderBy(p => p.PageNo)
                .ToListAsync(cancellationToken);
        var pagesByAsset = pages.ToLookup(p => p.AssetId);

        return rows.GroupBy(r => r.ArticleId).ToDictionary(g => g.Key, g =>
        {
            if (g.FirstOrDefault(r => r.Kind == MediaKind.Document) is { } doc)
            {
                return new ArticleAttachmentsDto(ArticleAttachmentsDto.DocumentKind, [], new DocumentAttachmentDto(
                    doc.AssetId,
                    doc.Title ?? string.Empty,
                    doc.PageCount ?? 0,
                    doc.AllowDownload,
                    CanDownload(doc.AllowDownload, doc.OwnerId, viewer),
                    urls.Absolute($"/documents/{doc.AssetId}/download"),
                    [.. pagesByAsset[doc.AssetId].Select(p => MediaMapping.Map<MediaAssetPage, MediaPageDto>(p, mapping, storage))]));
            }

            return new ArticleAttachmentsDto(ArticleAttachmentsDto.ImagesKind, [.. g.Select(image => new ImageAttachmentDto(
                image.AssetId,
                image.Order,
                image.Caption,
                image.AltText ?? string.Empty,
                image.Width ?? 0,
                image.Height ?? 0,
                image.BlurHash,
                [.. image.Variants.Select(v => MediaMapping.Map<MediaVariant, MediaVariantDto>(v, mapping, storage))]))], null);
        });
    }

    /// <summary>The author's switch, or the owner and moderators who may always download (ADR 0011).</summary>
    public static bool CanDownload(bool allowDownload, Guid ownerId, ICurrentUser? viewer) =>
        allowDownload
        || (viewer is not null && (viewer.UserId == ownerId || viewer.Permissions.Contains(Permissions.Moderation.Manage)));
}

internal static class ArticleAttachmentsExtensions
{
    /// <summary>Copies each card's attachments from <paramref name="attachments"/>; cards without any keep null.</summary>
    public static List<TCard> WithAttachments<TCard>(this IEnumerable<TCard> cards, IReadOnlyDictionary<Guid, ArticleAttachmentsDto> attachments)
        where TCard : ArticleCardDto =>
        [.. cards.Select(card => attachments.TryGetValue(card.Id, out var value) ? (TCard)((ArticleCardDto)card with { Attachments = value }) : card)];

    /// <summary>Applies the caller's download right to a cached card (owner or moderator).</summary>
    public static TCard PersonalizedFor<TCard>(this TCard card, ICurrentUser viewer) where TCard : ArticleCardDto
    {
        if (card.Attachments?.Document is not { CanDownload: false } document) return card;
        if (!ArticleAttachmentsReader.CanDownload(document.AllowDownload, card.Author.Id, viewer)) return card;
        return (TCard)((ArticleCardDto)card with
        {
            Attachments = card.Attachments with { Document = document with { CanDownload = true } },
        });
    }
}
