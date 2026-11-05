using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes.Commands.UndoShowLess;

internal sealed class UndoShowLessCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UndoShowLessCommand, Result>
{
    public async ValueTask<Result> Handle(UndoShowLessCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        await db.ArticleFeedback
            .Where(f => f.UserId == userId && f.ArticleId == command.ArticleId && f.Type == ArticleFeedbackType.ShowLess)
            .ExecuteDeleteAsync(cancellationToken);
        return Result.Success();
    }
}
