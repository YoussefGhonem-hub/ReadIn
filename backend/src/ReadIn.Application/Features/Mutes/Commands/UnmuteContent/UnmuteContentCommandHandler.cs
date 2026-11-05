using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Commands.UnmuteContent;

internal sealed class UnmuteContentCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UnmuteContentCommand, Result<ContentMutesDto>>
{
    public async ValueTask<Result<ContentMutesDto>> Handle(UnmuteContentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        await db.ContentMutes
            .Where(m => m.UserId == userId && m.TargetType == command.Target && m.TargetId == command.TargetId)
            .ExecuteDeleteAsync(cancellationToken);

        return await db.ContentMutesAsync(userId, cancellationToken);
    }
}
