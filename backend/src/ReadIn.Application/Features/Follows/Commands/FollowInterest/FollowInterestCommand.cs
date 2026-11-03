using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Commands.FollowInterest;

/// <summary>What an interest follows (SPEC F02, F12): a whole field or one topic.</summary>
public enum InterestTarget
{
    Field,
    Topic,
}

/// <summary>PUT /me/interests/fields/{id} and /me/interests/topics/{id} — follow one field or topic; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record FollowInterestCommand(InterestTarget Target, Guid TargetId) : ICommand<Result<InterestsDto>>;
