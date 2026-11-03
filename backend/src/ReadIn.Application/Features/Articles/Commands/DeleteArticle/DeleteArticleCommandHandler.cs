using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

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
        var article = await db.Articles.Include(a => a.Attachments)
            .FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId != currentUser.UserId) return ArticleErrors.NotOwner;

        var detached = article.SoftDelete(clock.GetUtcNow().UtcDateTime);
        var assets = await db.MediaAssets.Include(m => m.Pages).Where(m => detached.Contains(m.Id)).ToListAsync(cancellationToken);
        var paths = assets.SelectMany(a => a.StoredPaths()).ToList();
        db.MediaAssets.RemoveRange(assets);
        await db.SaveChangesAsync(cancellationToken);

        await files.DeleteAsync(paths, cancellationToken);
        await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug)], cancellationToken);
        return Result.Success();
    }
}
