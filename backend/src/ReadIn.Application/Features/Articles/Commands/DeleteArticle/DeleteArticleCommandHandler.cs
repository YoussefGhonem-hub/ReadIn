using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Commands.DeleteArticle;

internal sealed class DeleteArticleCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    MediaFiles files,
    HybridCache cache,
    TimeProvider clock)
    : ICommandHandler<DeleteArticleCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteArticleCommand command, CancellationToken cancellationToken)
    {
        var article = await db.Articles.Include(a => a.Attachments).Include(a => a.Draft)
            .FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId != currentUser.UserId) return ArticleErrors.NotOwner;

        var detached = article.SoftDelete(clock.GetUtcNow().UtcDateTime).ToHashSet();

        // The editor's working copy and revision history go with the article (F05), and so do the uploads they name.
        var documents = await db.ArticleRevisions.Where(r => r.ArticleId == article.Id).Select(r => r.DocumentJson).ToListAsync(cancellationToken);
        if (article.Draft is { } draft) documents.Add(draft.DocumentJson);
        detached.UnionWith(documents.SelectMany(json => ArticleDraftJson.Deserialize(json).Attachments).Select(a => a.MediaAssetId));
        await db.ArticleRevisions.Where(r => r.ArticleId == article.Id).ExecuteDeleteAsync(cancellationToken);
        article.DeleteDraft();

        // Only the author's own uploads that no other article shows or is writing with.
        var assets = new List<MediaAsset>();
        foreach (var asset in await db.MediaAssets.Include(m => m.Pages)
                     .Where(m => detached.Contains(m.Id) && m.OwnerId == article.AuthorId)
                     .Where(m => !db.ArticleAttachments.Any(x => x.MediaAssetId == m.Id && x.ArticleId != article.Id))
                     .ToListAsync(cancellationToken))
        {
            var id = asset.Id.ToString();
            if (!await db.ArticleDrafts.AnyAsync(d => d.ArticleId != article.Id && d.DocumentJson.Contains(id), cancellationToken)) assets.Add(asset);
        }
        var paths = assets.SelectMany(a => a.StoredPaths()).ToList();
        db.MediaAssets.RemoveRange(assets);
        await db.SaveChangesAsync(cancellationToken);

        await files.DeleteAsync(paths, cancellationToken);
        await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug), CacheTags.ArticleById(article.Id)], cancellationToken);
        return Result.Success();
    }
}
