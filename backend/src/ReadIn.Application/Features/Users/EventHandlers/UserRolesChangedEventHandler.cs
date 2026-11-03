using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.EventHandlers;

/// <summary>Role or suspension changes drop the cached permissions immediately (SPEC §9.2 step 5).</summary>
internal sealed class UserRolesChangedEventHandler(IAppDbContext db, IUserAccessService access)
    : IDomainEventHandler<UserRolesChangedDomainEvent>
{
    public async Task Handle(UserRolesChangedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var uid = await db.Users.AsNoTracking()
            .Where(u => u.Id == domainEvent.UserId)
            .Select(u => u.FirebaseUid)
            .FirstOrDefaultAsync(cancellationToken);
        if (uid is not null) await access.InvalidateAsync(uid, cancellationToken);
    }
}
