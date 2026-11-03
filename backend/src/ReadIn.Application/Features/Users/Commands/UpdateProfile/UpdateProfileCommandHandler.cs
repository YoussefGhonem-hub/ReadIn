using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

internal sealed class UpdateProfileCommandHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, UploadCleanup uploads)
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

        // Uploaded avatars are stored as relative paths; the absolute URL from GET /me maps back to the same path.
        var previousAvatar = user.AvatarUrl;
        var avatar = storage.ToStoredValue(command.AvatarUrl);

        var result = user.UpdateProfile(command.DisplayName, command.Username, command.Bio, avatar, links);
        if (result.IsFailure) return result;

        await db.SaveChangesAsync(cancellationToken);
        if (previousAvatar != avatar) await uploads.ReleaseAsync(previousAvatar, cancellationToken);
        return Result.Success();
    }
}
