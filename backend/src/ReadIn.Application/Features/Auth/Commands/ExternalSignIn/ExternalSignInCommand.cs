using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.ExternalSignIn;

/// <summary>
/// Continue with Google or Apple (SPEC §9.1, §9.2). Signs in when the identity is linked, or when its verified email
/// matches an account. Otherwise it answers <c>auth.external_not_linked</c> and the client asks again with either
/// <see cref="Link"/> (the phone + password of an existing account) or <see cref="CreateAccount"/>.
/// </summary>
/// <param name="DisplayName">Apple sends the name to the app only on the first authorization; used for new accounts.</param>
public sealed record ExternalSignInCommand(
    string Provider,
    string IdToken,
    string? Nonce = null,
    string? DisplayName = null,
    string? UiLanguage = null,
    string? TimeZone = null,
    PhoneAccountLinkDto? Link = null,
    bool CreateAccount = false,
    string? AuthorizationCode = null) : ICommand<Result<AuthSessionDto>>;

/// <summary>Proves the person owns an existing phone account, so the Google/Apple identity is added to it.</summary>
public sealed record PhoneAccountLinkDto(string PhoneNumber, string Password);

internal sealed class ExternalSignInCommandValidator : AbstractValidator<ExternalSignInCommand>
{
    public ExternalSignInCommandValidator()
    {
        RuleFor(c => new ExternalCredentialDto(c.Provider, c.IdToken, c.Nonce, c.AuthorizationCode))
            .SetValidator(new ExternalCredentialValidator())
            .OverridePropertyName(string.Empty);
        RuleFor(c => c.DisplayName).MaximumLength(200);
        RuleFor(c => c.TimeZone).MaximumLength(64);
        RuleFor(c => c.Link!.PhoneNumber).NotEmpty().MaximumLength(32).When(c => c.Link is not null);
        RuleFor(c => c.Link!.Password).NotEmpty().MaximumLength(PasswordRules.MaxLength).When(c => c.Link is not null);
        RuleFor(c => c.CreateAccount).Equal(false).When(c => c.Link is not null)
            .WithMessage("Send either link or createAccount, not both.");
    }
}
