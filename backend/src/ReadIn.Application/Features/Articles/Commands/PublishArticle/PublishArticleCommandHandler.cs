using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.PublishArticle;

internal sealed class PublishArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<PublishArticleCommand, Result>
{
    public async ValueTask<Result> Handle(PublishArticleCommand command, CancellationToken cancellationToken)
    {
        var article = await db.Articles
            .Include(a => a.Translations)
            .Include(a => a.Sources)
            .FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null) return ArticleErrors.NotFound;
        if (article.AuthorId != currentUser.UserId) return ArticleErrors.NotOwner;

        var field = await db.Fields.AsNoTracking().FirstAsync(f => f.Id == article.FieldId, cancellationToken);

        var result = article.Publish(field, clock.GetUtcNow().UtcDateTime);
        if (result.IsFailure) return result;

        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
