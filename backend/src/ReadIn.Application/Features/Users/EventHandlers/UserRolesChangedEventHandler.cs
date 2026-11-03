using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.EventHandlers;

/// <summary>Role or suspension changes drop the cached permissions immediately (SPEC §9.3).</summary>
internal sealed class UserRolesChangedEventHandler(IUserAccessService access)
    : IDomainEventHandler<UserRolesChangedDomainEvent>
{
    public async Task Handle(UserRolesChangedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        await access.InvalidateAsync(domainEvent.UserId, cancellationToken);
}
