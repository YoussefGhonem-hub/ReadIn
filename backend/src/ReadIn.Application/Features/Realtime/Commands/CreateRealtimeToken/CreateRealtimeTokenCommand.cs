using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Realtime.Commands.CreateRealtimeToken;

/// <summary>
/// POST /realtime/token — a Firebase custom token that lets the signed-in user read <c>/live/users/{id}</c> in the
/// Realtime Database (SPEC §21.2). Guests read the public paths without one.
/// </summary>
[Authenticated]
public sealed record CreateRealtimeTokenCommand : ICommand<Result<RealtimeTokenDto>>;

/// <summary>Passed to <c>signInWithCustomToken</c> on the client's own Firebase app; valid for one hour.</summary>
public sealed record RealtimeTokenDto(string Token);
