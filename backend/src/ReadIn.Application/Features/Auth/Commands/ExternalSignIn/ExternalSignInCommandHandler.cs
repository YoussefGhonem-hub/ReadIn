using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.ExternalSignIn;

internal sealed class ExternalSignInCommandHandler(
    IAppDbContext db,
    ExternalCredentialVerifier externalIdentities,
    PasswordSignIn passwordSignIn,
    SessionIssuer sessions,
    AuditTrail audit,
    AppleTokens appleTokens,
    TimeProvider clock)
    : ICommandHandler<ExternalSignInCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(ExternalSignInCommand command, CancellationToken cancellationToken)
    {
        var verified = await externalIdentities.VerifyAsync(
            command.Provider, command.IdToken, command.Nonce, command.AuthorizationCode, cancellationToken);
        if (verified.IsFailure) return verified.Error;

        var identity = verified.Value;
        var now = clock.GetUtcNow().UtcDateTime;
        var linked = await db.Users.Include(u => u.ExternalLogins)
            .FirstOrDefaultAsync(u => u.ExternalLogins.Any(l => l.Provider == identity.Provider && l.Subject == identity.Subject), cancellationToken);

        if (command.Link is { } link)
        {
            var owner = await passwordSignIn.AuthenticateAsync(link.PhoneNumber, link.Password, cancellationToken);
            if (owner.IsFailure) return owner.Error;
            if (linked is not null && linked.Id != owner.Value.Id) return CredentialErrors.ExternalInUse;
            return await LinkAndStartAsync(owner.Value, identity, command.AuthorizationCode, now, cancellationToken);
        }

        if (linked is not null) return await StartAsync(linked, identity, command.AuthorizationCode, now, cancellationToken);

        // Only provider-verified addresses are ever stored in Users.Email, so a verified match is the same person (SPEC §9.1).
        if (identity is { EmailVerified: true, Email: { } email })
        {
            var byEmail = await db.Users.Include(u => u.ExternalLogins)
                .FirstOrDefaultAsync(u => u.Email == email && !u.IsSystemAccount, cancellationToken);
            if (byEmail is not null) return await LinkAndStartAsync(byEmail, identity, command.AuthorizationCode, now, cancellationToken);
        }

        if (!command.CreateAccount) return CredentialErrors.ExternalNotLinked;
        return await RegisterAsync(command, identity, now, cancellationToken);
    }

    private async Task<Result<AuthSessionDto>> StartAsync(
        User user, ExternalIdentity identity, string? authorizationCode, DateTime now, CancellationToken ct)
    {
        if (user.IsSuspendedAt(now)) return UserErrors.SuspendedUntil(user.SuspendedUntil);
        user.RecordExternalSignIn(identity.Provider, now);
        await appleTokens.CaptureAsync(user, identity, authorizationCode, ct);
        return await sessions.StartAsync(user, ct);
    }

    private async Task<Result<AuthSessionDto>> LinkAndStartAsync(
        User user, ExternalIdentity identity, string? authorizationCode, DateTime now, CancellationToken ct)
    {
        if (user.IsSuspendedAt(now)) return UserErrors.SuspendedUntil(user.SuspendedUntil);

        var alreadyLinked = user.FindExternalLogin(identity.Provider) is not null;
        var linked = user.LinkExternalLogin(identity.Provider, identity.Subject, identity.Email, now);
        if (linked.IsFailure) return linked.Error;
        if (!alreadyLinked) audit.Record(AuditActions.ExternalLoginLinked, user.Id);
        await appleTokens.CaptureAsync(user, identity, authorizationCode, ct);

        try
        {
            return await sessions.StartAsync(user, ct);
        }
        catch (DbUpdateException) when (!alreadyLinked)
        {
            return CredentialErrors.ExternalInUse; // the same identity was linked to another account at the same moment
        }
    }

    private async Task<Result<AuthSessionDto>> RegisterAsync(
        ExternalSignInCommand command, ExternalIdentity identity, DateTime now, CancellationToken ct)
    {
        // A soft-deleted account keeps its email until it is anonymized (SPEC F01): the new account then starts without one.
        var email = identity is { EmailVerified: true, Email: { } address } &&
            !await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Email == address, ct)
                ? address
                : null;

        var user = User.RegisterExternal(
            identity.Provider,
            identity.Subject,
            email,
            command.DisplayName ?? identity.Name,
            await NewAccounts.PlaceholderUsernameAsync(db, ct),
            RoleIds.Member,
            now,
            command.UiLanguage,
            NewAccounts.ValidTimeZoneOrNull(command.TimeZone));
        db.Users.Add(user);
        audit.Record(AuditActions.ExternalSignUp, user.Id);
        await appleTokens.CaptureAsync(user, identity, command.AuthorizationCode, ct);

        try
        {
            return await sessions.StartAsync(user, ct);
        }
        catch (DbUpdateException)
        {
            // Created by a parallel request (e.g. a double tap); that request has the session.
            if (await db.Users.AsNoTracking().AnyAsync(
                    u => u.ExternalLogins.Any(l => l.Provider == identity.Provider && l.Subject == identity.Subject), ct))
                return CredentialErrors.ExternalInUse;
            throw;
        }
    }
}
