using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.SyncUser;

/// <summary>
/// POST /auth/sync — creates the ReadIn user on first sign-in (role Member) and refreshes identity
/// data afterwards (SPEC §9.2 step 4). Identity fields come from the verified Firebase token, not the body.
/// </summary>
public sealed record SyncUserCommand(string? UiLanguage, string? TimeZone) : ICommand<Result<MeDto>>;
