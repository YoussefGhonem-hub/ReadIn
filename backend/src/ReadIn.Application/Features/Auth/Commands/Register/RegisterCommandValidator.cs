using FluentValidation;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Security;

namespace ReadIn.Application.Features.Auth.Commands.Register;

internal sealed class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator(IOptions<RecoveryOptions> recovery)
    {
        RuleFor(c => c.PhoneNumber).PhoneNumber();
        RuleFor(c => c.Password).Password(c => c.PhoneNumber);
        RuleFor(c => c.RecoveryPin).RecoveryPin(recovery.Value.PinLength);
        RuleFor(c => c.TimeZone).MaximumLength(64);
    }
}
