using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Commands.UnmuteUser;

/// <summary>
/// DELETE /users/{id}/mute?restoreFollow= — unmute a writer; idempotent. <see cref="RestoreFollow"/> also follows them
/// again in the same request: the Undo of a mute that ended a follow (<see cref="UserMuteStateDto.FollowRemoved"/>).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record UnmuteUserCommand(Guid UserId, bool RestoreFollow) : ICommand<Result<UserMuteStateDto>>;
