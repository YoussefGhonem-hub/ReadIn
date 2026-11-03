using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Follows.Commands.FollowInterest;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Commands.UnfollowInterest;

/// <summary>
/// DELETE /me/interests/fields/{id} and /me/interests/topics/{id} — unfollow one field or topic; idempotent, but
/// <c>400 user.interests.min_three</c> when it would leave fewer than 3 interests (SPEC F02).
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Follows.Manage)]
public sealed record UnfollowInterestCommand(InterestTarget Target, Guid TargetId) : ICommand<Result<InterestsDto>>;
