using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.DeleteAccount;

/// <summary>
/// Delete account (SPEC F01): confirmed with the password, or with a fresh Google/Apple sign in (the only option without a
/// password, and the one that also lets Apple's token be revoked when none is stored). Apple tokens are revoked first, then
/// everything in the data map (SPEC §9.6) is deleted at once, in one transaction: there is no grace period and nothing to
/// restore. Every session ends with the account, and the phone number, email and Google/Apple identities can sign up again
/// right away as a new account. A failure leaves the account as it was.
/// </summary>
[Authenticated]
public sealed record DeleteAccountCommand(string? Password = null, ExternalCredentialDto? External = null) : ICommand<Result>;

internal sealed class DeleteAccountCommandValidator : AbstractValidator<DeleteAccountCommand>
{
    public DeleteAccountCommandValidator()
    {
        RuleFor(c => c.Password).MaximumLength(PasswordRules.MaxLength);
        RuleFor(c => c.External!).SetValidator(new ExternalCredentialValidator()).When(c => c.External is not null);
    }
}

internal sealed class DeleteAccountCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IdentityConfirmation confirmation,
    AppleTokens appleTokens,
    IRealtimeAccountData realtime,
    IAccountEraser eraser,
    IUserAccessService access)
    : ICommandHandler<DeleteAccountCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteAccountCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.ExternalLogins).FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
        if (user is null) return Result.Success(); // deleted by an earlier request: same outcome

        var confirmed = await confirmation.ConfirmWithIdentityAsync(user, command.Password, command.External, cancellationToken);
        if (confirmed.IsFailure) return confirmed.Error;

        var revoked = await appleTokens.RevokeAsync(user, confirmed.Value, command.External?.AuthorizationCode, cancellationToken);
        if (revoked.IsFailure) return revoked.Error;

        var forgotten = await realtime.DeleteIdentityAsync(userId, cancellationToken);
        if (forgotten.IsFailure) return forgotten.Error;

        await eraser.EraseAsync(userId, cancellationToken);
        await access.InvalidateAsync(userId, cancellationToken);
        return Result.Success();
    }
}
