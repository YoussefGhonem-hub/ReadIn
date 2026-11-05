using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.CompleteProfile;

internal sealed class CompleteProfileCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IFileStorage storage,
    UploadCleanup uploads,
    MeReader meReader,
    AuthorCaches authorCaches)
    : ICommandHandler<CompleteProfileCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(CompleteProfileCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        if (command.Username != user.Username &&
            await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Username == command.Username, cancellationToken))
            return UserErrors.UsernameTaken;

        var previousAvatar = user.AvatarUrl;
        var shown = (user.DisplayName, user.Username, user.AvatarUrl, user.Headline);
        var avatar = storage.ToStoredValue(command.AvatarUrl);
        var result = user.CompleteProfile(command.DisplayName, command.Username, avatar);
        if (result.IsFailure) return result.Error;
        if (command.Headline is { } headline && user.SetHeadline(headline.Value) is { IsFailure: true } badHeadline) return badHeadline.Error;

        await db.SaveChangesAsync(cancellationToken);
        if (previousAvatar != avatar) await uploads.ReleaseAsync(previousAvatar, cancellationToken);
        if (shown != (user.DisplayName, user.Username, user.AvatarUrl, user.Headline)) await authorCaches.DropAsync(user.Id, cancellationToken);
        return await meReader.ReadAsync(userId, cancellationToken);
    }
}
