using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.SignIn;

public sealed record SignInCommand(string PhoneNumber, string Password) : ICommand<Result<AuthSessionDto>>;

internal sealed class SignInCommandValidator : AbstractValidator<SignInCommand>
{
    public SignInCommandValidator()
    {
        RuleFor(c => c.PhoneNumber).NotEmpty().MaximumLength(32);
        RuleFor(c => c.Password).NotEmpty().MaximumLength(PasswordRules.MaxLength);
    }
}
