using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Commands.SetArticleAttachments;

internal sealed class SetArticleAttachmentsCommandHandler(IAppDbContext db, ICurrentUser currentUser, HybridCache cache)
    : ICommandHandler<SetArticleAttachmentsCommand, Result>
{
    public async ValueTask<Result> Handle(SetArticleAttachmentsCommand command, CancellationToken cancellationToken)
    {
        var article = await db.Articles.Include(a => a.Attachments)
            .FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId != currentUser.UserId) return ArticleErrors.NotOwner;

        var ids = command.Items.Select(i => i.MediaAssetId).Distinct().ToList();
        var assets = await db.MediaAssets.Where(m => ids.Contains(m.Id)).ToDictionaryAsync(m => m.Id, cancellationToken);
        if (assets.Count != ids.Count) return AttachmentErrors.AssetNotFound;

        // An asset shows in one post only.
        if (await db.ArticleAttachments.AnyAsync(a => ids.Contains(a.MediaAssetId) && a.ArticleId != article.Id, cancellationToken))
            return MediaErrors.InUse;

        var candidates = command.Items
            .Select(i => new AttachmentCandidate(i.MediaAssetId, assets[i.MediaAssetId].Kind, assets[i.MediaAssetId].Status,
                assets[i.MediaAssetId].OwnerId, i.Order, i.Caption, i.AltText))
            .ToList();
        var result = article.SetAttachments(candidates);
        if (result.IsFailure) return result;

        foreach (var item in command.Items.Where(i => assets[i.MediaAssetId].Kind == MediaKind.Document))
        {
            var document = assets[item.MediaAssetId];
            var settings = document.UpdateDocumentSettings(item.Title ?? document.Title, item.AllowDownload ?? document.AllowDownload);
            if (settings.IsFailure) return settings;
        }

        // Assets dropped from the set stay as unattached uploads; the client deletes them, or the orphan cleanup does.
        await db.SaveChangesAsync(cancellationToken);
        if (article.IsPublished)
            await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug)], cancellationToken);
        return Result.Success();
    }
}
