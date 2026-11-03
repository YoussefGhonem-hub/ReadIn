using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

/// <summary>Builds <see cref="MeDto"/>; shared by GET /me and POST /auth/sync.</summary>
internal sealed class MeReader(IAppDbContext db, IUserAccessService access, IMapper mapper)
{
    public async Task<Result<MeDto>> ReadAsync(string firebaseUid, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking()
            .Include(u => u.Interests)
            .FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid, ct);
        if (user is null) return UserErrors.NotSynced;

        var userAccess = await access.GetAsync(firebaseUid, ct);
        var roles = userAccess?.Roles ?? [];

        return mapper.Map<MeDto>(user) with
        {
            Roles = roles,
            Permissions = userAccess?.Permissions ?? [],
            IsVerified = roles.Contains(RoleNames.VerifiedWriter),
        };
    }
}
