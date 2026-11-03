using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.ChangePhoneNumber;

/// <summary>"تغيير الرقم" (SPEC F18): new number + current password, after the confirm-number dialog. Signs out other sessions.</summary>
[Authenticated]
public sealed record ChangePhoneNumberCommand(string NewPhoneNumber, string CurrentPassword) : ICommand<Result<AuthSessionDto>>;

internal sealed class ChangePhoneNumberCommandValidator : AbstractValidator<ChangePhoneNumberCommand>
{
    public ChangePhoneNumberCommandValidator()
    {
        RuleFor(c => c.NewPhoneNumber).PhoneNumber();
        RuleFor(c => c.CurrentPassword).NotEmpty().MaximumLength(PasswordRules.MaxLength);
    }
}
