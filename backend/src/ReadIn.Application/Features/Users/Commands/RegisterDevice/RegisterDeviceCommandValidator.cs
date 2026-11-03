using FluentValidation;

namespace ReadIn.Application.Features.Users.Commands.RegisterDevice;

internal sealed class RegisterDeviceCommandValidator : AbstractValidator<RegisterDeviceCommand>
{
    public RegisterDeviceCommandValidator()
    {
        RuleFor(c => c.Token).NotEmpty().MaximumLength(4096);
        RuleFor(c => c.Platform).IsInEnum();
    }
}
