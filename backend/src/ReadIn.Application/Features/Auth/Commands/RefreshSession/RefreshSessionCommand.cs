using FluentValidation;
using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.RefreshSession;

/// <summary>The web sends no body: its refresh token comes from the <c>HttpOnly</c> cookie (SPEC §9.3).</summary>
/// <param name="RetryKey">
/// A random key the mobile app stores before it refreshes and sends again with the same old token when the answer never
/// arrived (timeout, lost response, app killed). Empty counts as absent.
/// </param>
public sealed record RefreshSessionCommand(string? RefreshToken, string? RetryKey = null) : ICommand<Result<AuthSessionDto>>;

internal sealed class RefreshSessionCommandValidator : AbstractValidator<RefreshSessionCommand>
{
    public RefreshSessionCommandValidator()
    {
        RuleFor(c => c.RetryKey).MaximumLength(200);
    }
}
