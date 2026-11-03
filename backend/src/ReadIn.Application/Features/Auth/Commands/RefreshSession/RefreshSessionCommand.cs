using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.RefreshSession;

/// <summary>The web sends no body: its refresh token comes from the <c>HttpOnly</c> cookie (SPEC §9.3).</summary>
public sealed record RefreshSessionCommand(string? RefreshToken) : ICommand<Result<AuthSessionDto>>;
