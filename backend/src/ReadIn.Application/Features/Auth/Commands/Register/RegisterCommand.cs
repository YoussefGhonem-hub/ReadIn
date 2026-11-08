using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.Register;

/// <summary>
/// Create account (SPEC §9.2): phone + password + recovery PIN, sent after the client's "confirm your number" step.
/// <paramref name="AcceptTerms"/> must be true: the Terms of Use and Community Guidelines box (F37).
/// </summary>
public sealed record RegisterCommand(
    string PhoneNumber,
    string Password,
    string RecoveryPin,
    string? UiLanguage = null,
    string? TimeZone = null,
    bool? AcceptTerms = null) : ICommand<Result<AuthSessionDto>>;
