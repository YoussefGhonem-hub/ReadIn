using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes.Commands.UnmuteContent;

/// <summary>DELETE /me/mutes/fields/{id} and /me/mutes/topics/{id} — unmute a field or a topic; idempotent, any id.</summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record UnmuteContentCommand(ContentMuteTarget Target, Guid TargetId) : ICommand<Result<ContentMutesDto>>;
