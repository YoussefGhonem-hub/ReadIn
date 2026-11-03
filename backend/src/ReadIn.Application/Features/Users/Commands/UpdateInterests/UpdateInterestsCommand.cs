using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdateInterests;

/// <summary>PUT /me/interests — onboarding step 2, at least 3 fields/topics combined (SPEC F02).</summary>
[Authenticated]
public sealed record UpdateInterestsCommand(IReadOnlyList<Guid> FieldIds, IReadOnlyList<Guid> TopicIds) : ICommand<Result>;
