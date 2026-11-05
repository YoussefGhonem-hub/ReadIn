using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes.Commands.MuteContent;

/// <summary>
/// PUT /me/mutes/fields/{id} and /me/mutes/topics/{id} — mute a field or a topic (SPEC F28); idempotent. Your interests
/// stay as they are; a mute wins over an interest.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record MuteContentCommand(ContentMuteTarget Target, Guid TargetId) : ICommand<Result<ContentMutesDto>>;
