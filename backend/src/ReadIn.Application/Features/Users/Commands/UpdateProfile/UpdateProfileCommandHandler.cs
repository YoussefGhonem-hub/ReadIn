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
    // Also named in `errors`, so clients can show them next to the field.
    internal static readonly Error AvatarInvalid = ProfileErrors.AvatarInvalid with
    {
        Details = new Dictionary<string, string[]> { ["avatarAssetId"] = [ProfileErrors.AvatarInvalid.Code] },
    };

    internal static readonly Error ExpertiseInvalid = ProfileErrors.ExpertiseInvalid with
    {
        Details = new Dictionary<string, string[]> { ["expertiseFieldIds"] = [ProfileErrors.ExpertiseInvalid.Code] },
    };

    public async ValueTask<Result> Handle(UpdateProfileCommand command, CancellationToken cancellationToken)
    {
        var expertise = command.ExpertiseFieldIds?.Distinct().ToList();
        if (expertise?.Count > User.MaxExpertiseFields) return ExpertiseInvalid;

        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.Expertise).FirstAsync(u => u.Id == userId, cancellationToken);

        if (command.Username != user.Username &&
            await db.Users.AnyAsync(u => u.Username == command.Username, cancellationToken))
            return UserErrors.UsernameTaken;

        var links = new UserLinks
        {
            GitHub = command.Links?.GitHub,
            LinkedIn = command.Links?.LinkedIn,
            Website = command.Links?.Website,
        };

        var previousAvatar = user.AvatarUrl;
        var avatar = await StoredAvatarAsync(command.Avatar, user, cancellationToken);
        if (avatar.IsFailure) return avatar.Error;

        if (expertise is not null)
        {
            var known = await db.Fields.CountAsync(f => expertise.Contains(f.Id) && f.IsEnabled, cancellationToken);
            if (known != expertise.Count) return ExpertiseInvalid;
            if (user.SetExpertise(expertise).IsFailure) return ExpertiseInvalid;
        }

        var result = user.UpdateProfile(command.DisplayName, command.Username, command.Bio, avatar.Value, links);
        if (result.IsFailure) return result;

        await db.SaveChangesAsync(cancellationToken);
        if (previousAvatar != avatar.Value) await uploads.ReleaseAsync(previousAvatar, cancellationToken);
        return Result.Success();
    }

    /// <summary>What <c>Users.AvatarUrl</c> becomes: the 256 px variant of an avatar upload, a legacy URL, or nothing.</summary>
    private async Task<Result<string?>> StoredAvatarAsync(AvatarChange? change, User user, CancellationToken ct)
    {
        switch (change)
        {
            case null:
                return user.AvatarUrl;

            case { AssetId: { } assetId }:
                var asset = await db.MediaAssets.AsNoTracking().FirstOrDefaultAsync(a => a.Id == assetId, ct);
                if (asset is null || !asset.IsUsableBy(user.Id)) return AvatarInvalid;
                return Avatars.ForSlot(asset.Variants, Avatars.StoredWidth).Path;

            default:
                // Uploaded avatars are stored as relative paths; the absolute URL from GET /me maps back to the same path.
                return storage.ToStoredValue(change.Url);
        }
    }
}
