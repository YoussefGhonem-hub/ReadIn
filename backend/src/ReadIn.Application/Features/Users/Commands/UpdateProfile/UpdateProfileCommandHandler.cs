using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

internal sealed class UpdateProfileCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdateProfileCommand, Result>
{
    public async ValueTask<Result> Handle(UpdateProfileCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        if (command.Username != user.Username &&
            await db.Users.AnyAsync(u => u.Username == command.Username, cancellationToken))
            return UserErrors.UsernameTaken;

        var links = new UserLinks
        {
            GitHub = command.Links?.GitHub,
            LinkedIn = command.Links?.LinkedIn,
            Website = command.Links?.Website,
        };

        var result = user.UpdateProfile(command.DisplayName, command.Username, command.Bio, command.AvatarUrl, links);
        if (result.IsFailure) return result;

        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
