using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Commands.FollowUser;

/// <summary>PUT /users/{id}/follow — follow a writer, the official ReadIn account included; idempotent (SPEC F12).</summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record FollowUserCommand(Guid UserId) : ICommand<Result<FollowStateDto>>;
