using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions.Commands.SetReaction;

internal sealed class SetReactionCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<SetReactionCommand, Result<ArticleReactionsDto>>
{
    public async ValueTask<Result<ArticleReactionsDto>> Handle(SetReactionCommand command, CancellationToken cancellationToken)
    {
        if (!ReactionTypes.TryParse(command.Type, out var type)) throw new InvalidOperationException("The validator checks the type.");
        if (!await db.Articles.VisibleTo(currentUser).AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var userId = currentUser.RequireUserId();
        var existing = await db.Reactions.FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
        var reaction = Reaction.Set(existing, userId, command.ArticleId, type, clock.GetUtcNow().UtcDateTime);
        if (existing is null) db.Reactions.Add(reaction);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException) when (existing is null)
        {
            // Two first reactions at once (a double tap): the unique index kept the one that committed first.
            var current = await db.Reactions.AsNoTracking()
                .Where(r => r.UserId == userId && r.ArticleId == command.ArticleId)
                .Select(r => (ReactionType?)r.Type)
                .FirstOrDefaultAsync(cancellationToken);
            if (current is null) throw;
            return await ArticleReactions.ReadAsync(db, command.ArticleId, current, cancellationToken);
        }

        return await ArticleReactions.ReadAsync(db, command.ArticleId, type, cancellationToken);
    }
}
