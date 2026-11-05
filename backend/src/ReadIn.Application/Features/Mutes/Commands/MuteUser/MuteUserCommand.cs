using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Mutes.Commands.MuteUser;

/// <summary>
/// PUT /users/{id}/mute — mute a writer (SPEC F28): their articles and activity leave your lists and notifications, their
/// comments collapse, and your follow of them ends. Idempotent. Not yourself, not the official ReadIn account.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record MuteUserCommand(Guid UserId) : ICommand<Result<UserMuteStateDto>>;
