using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Commands.UnfollowUser;

/// <summary>DELETE /users/{id}/follow — unfollow; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record UnfollowUserCommand(Guid UserId) : ICommand<Result<FollowStateDto>>;
