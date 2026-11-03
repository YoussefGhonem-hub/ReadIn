using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.Register;

/// <summary>Create account (SPEC §9.2): phone + password + recovery PIN, sent after the client's "confirm your number" step.</summary>
public sealed record RegisterCommand(
    string PhoneNumber,
    string Password,
    string RecoveryPin,
    string? UiLanguage = null,
    string? TimeZone = null) : ICommand<Result<AuthSessionDto>>;
