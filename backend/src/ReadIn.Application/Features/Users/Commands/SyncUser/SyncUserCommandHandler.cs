using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.SyncUser;

internal sealed class SyncUserCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IUserAccessService access,
    MeReader meReader)
    : ICommandHandler<SyncUserCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(SyncUserCommand command, CancellationToken cancellationToken)
    {
        if (!currentUser.IsAuthenticated || currentUser.FirebaseUid is null) return AuthErrors.Unauthorized;
        if (string.IsNullOrWhiteSpace(currentUser.Email)) return SyncErrors.EmailRequired;

        var uid = currentUser.FirebaseUid;
        var user = await db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == uid, cancellationToken);

        if (user is null)
        {
            var username = await UniqueUsernameAsync(User.SuggestUsername(currentUser.Email), cancellationToken);
            user = User.Register(
                uid,
                currentUser.Email,
                currentUser.DisplayName ?? string.Empty,
                username,
                currentUser.PictureUrl,
                RoleIds.Member,
                command.UiLanguage ?? currentUser.UiLanguage,
                ValidTimeZoneOrNull(command.TimeZone));
            db.Users.Add(user);
        }
        else
        {
            user.SyncIdentity(currentUser.Email, currentUser.PictureUrl);
        }

        await db.SaveChangesAsync(cancellationToken);
        await access.InvalidateAsync(uid, cancellationToken);

        return await meReader.ReadAsync(uid, cancellationToken);
    }

    private async Task<string> UniqueUsernameAsync(string candidate, CancellationToken ct)
    {
        var taken = await db.Users.AsNoTracking()
            .Where(u => u.Username.StartsWith(candidate))
            .Select(u => u.Username)
            .ToListAsync(ct);
        if (!taken.Contains(candidate)) return candidate;

        for (var i = 2; ; i++)
        {
            var next = $"{candidate}{i}";
            if (!taken.Contains(next)) return next;
        }
    }

    private static string? ValidTimeZoneOrNull(string? timeZone) =>
        timeZone is not null && TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out _) ? timeZone : null;
}

internal static class SyncErrors
{
    public static readonly Error EmailRequired =
        Error.Validation("auth.email_required", "The sign-in provider did not share an email address.");
}
