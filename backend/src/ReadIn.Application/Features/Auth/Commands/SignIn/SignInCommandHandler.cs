using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.SignIn;

/// <summary>Sign in with phone + password (SPEC §9.2); the limits are in <see cref="PasswordSignIn"/>.</summary>
internal sealed class SignInCommandHandler(PasswordSignIn passwordSignIn, SessionIssuer sessions)
    : ICommandHandler<SignInCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(SignInCommand command, CancellationToken cancellationToken)
    {
        var user = await passwordSignIn.AuthenticateAsync(command.PhoneNumber, command.Password, cancellationToken);
        return user.IsFailure ? user.Error : await sessions.StartAsync(user.Value, cancellationToken);
    }
}
