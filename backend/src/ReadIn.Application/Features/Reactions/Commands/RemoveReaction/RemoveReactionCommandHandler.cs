using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reactions.Commands.RemoveReaction;

internal sealed class RemoveReactionCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<RemoveReactionCommand, Result<ArticleReactionsDto>>
{
    public async ValueTask<Result<ArticleReactionsDto>> Handle(RemoveReactionCommand command, CancellationToken cancellationToken)
    {
        if (!await db.Articles.Visible().AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        var reaction = await db.Reactions.FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
        if (reaction is not null)
        {
            reaction.Remove();
            db.Reactions.Remove(reaction);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateConcurrencyException)
            {
                // Removed by a concurrent request: the outcome is the same.
            }
        }

        return await ArticleReactions.ReadAsync(db, command.ArticleId, mine: null, cancellationToken);
    }
}
