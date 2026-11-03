using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.ExternalLogins;

/// <summary>
/// Settings → Account → link Google or Apple (SPEC F18). Confirmed with the password, or with a fresh token of an
/// identity already linked, so a stolen access token can't add a way back in.
/// </summary>
[Authenticated]
public sealed record LinkExternalLoginCommand(ExternalCredentialDto Credential, string? Password = null, ExternalCredentialDto? External = null)
    : ICommand<Result<MeDto>>;

internal sealed class LinkExternalLoginCommandValidator : AbstractValidator<LinkExternalLoginCommand>
{
    public LinkExternalLoginCommandValidator()
    {
        RuleFor(c => c.Credential).NotNull().SetValidator(new ExternalCredentialValidator());
        RuleFor(c => c.Password).MaximumLength(PasswordRules.MaxLength);
        RuleFor(c => c.External!).SetValidator(new ExternalCredentialValidator()).When(c => c.External is not null);
    }
}

internal sealed class LinkExternalLoginCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IdentityConfirmation confirmation,
    IExternalIdentityVerifier externalIdentities,
    AuditTrail audit,
    MeReader meReader,
    TimeProvider clock)
    : ICommandHandler<LinkExternalLoginCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(LinkExternalLoginCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.ExternalLogins).FirstAsync(u => u.Id == userId, cancellationToken);

        if (await confirmation.ConfirmAsync(user, command.Password, command.External, cancellationToken) is { } error) return error;

        var credential = command.Credential;
        var verified = await externalIdentities.VerifyAsync(credential.Provider, credential.IdToken, credential.Nonce, cancellationToken);
        if (verified.IsFailure) return verified.Error;

        var identity = verified.Value;
        var usedElsewhere = await db.Users.IgnoreQueryFilters().AnyAsync(
            u => u.Id != userId && u.ExternalLogins.Any(l => l.Provider == identity.Provider && l.Subject == identity.Subject),
            cancellationToken);
        if (usedElsewhere) return CredentialErrors.ExternalInUse;

        var linked = user.LinkExternalLogin(identity.Provider, identity.Subject, identity.Email, clock.GetUtcNow().UtcDateTime);
        if (linked.IsFailure) return linked.Error;
        audit.Record(AuditActions.ExternalLoginLinked, userId);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return CredentialErrors.ExternalInUse; // linked to another account at the same moment
        }
        return await meReader.ReadAsync(userId, cancellationToken);
    }
}

/// <summary>Settings → Account → unlink Google or Apple; refused when it's the only way left to sign in.</summary>
[Authenticated]
public sealed record UnlinkExternalLoginCommand(string Provider) : ICommand<Result<MeDto>>;

internal sealed class UnlinkExternalLoginCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    AuditTrail audit,
    MeReader meReader)
    : ICommandHandler<UnlinkExternalLoginCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(UnlinkExternalLoginCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.Include(u => u.ExternalLogins).FirstAsync(u => u.Id == userId, cancellationToken);

        var unlinked = user.UnlinkExternalLogin(command.Provider);
        if (unlinked.IsFailure) return unlinked.Error;

        audit.Record(AuditActions.ExternalLoginUnlinked, userId);
        await db.SaveChangesAsync(cancellationToken);
        return await meReader.ReadAsync(userId, cancellationToken);
    }
}
