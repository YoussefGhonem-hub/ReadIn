using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

/// <summary>Builds <see cref="MeDto"/>; shared by GET /me and every call that starts or refreshes a session.</summary>
internal sealed class MeReader(IAppDbContext db, IUserAccessService access, IMapper mapper, IFileStorage storage)
{
    public async Task<Result<MeDto>> ReadAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking()
            .Include(u => u.Interests)
            .Include(u => u.ExternalLogins)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null) return UserErrors.NotFound;

        var userAccess = await access.GetAsync(userId, ct);

        // IsVerified is the badge on the user (SPEC §10.1), mapped with the rest; roles never carry it.
        return mapper.Map<MeDto>(user) with
        {
            AvatarUrl = storage.ToPublicUrl(user.AvatarUrl),
            Roles = userAccess?.Roles ?? [],
            Permissions = userAccess?.Permissions ?? [],
        };
    }
}
