using System.Security.Cryptography;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.Register;

internal sealed class RegisterCommandHandler(
    IAppDbContext db,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    SessionIssuer sessions,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<RegisterCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(RegisterCommand command, CancellationToken cancellationToken)
    {
        if (!PhoneNumberRules.TryNormalize(command.PhoneNumber, out var phone)) return CredentialErrors.InvalidCredentials;
        // Soft-deleted accounts keep their number until they are anonymized (SPEC F01).
        if (await IsTakenAsync(phone, cancellationToken)) return CredentialErrors.PhoneTaken;

        var user = User.Register(
            phone,
            passwords.Hash(command.Password),
            await PlaceholderUsernameAsync(cancellationToken),
            RoleIds.Member,
            command.UiLanguage,
            ValidTimeZoneOrNull(command.TimeZone));
        db.Users.Add(user); // assigns the id that the PIN hash is bound to
        user.SetRecoveryPin(pins.Hash(user.Id, RecoveryPinRules.Normalize(command.RecoveryPin)), clock.GetUtcNow().UtcDateTime);
        audit.Record(AuditActions.SignUp, user.Id);

        try
        {
            return await sessions.StartAsync(user, cancellationToken);
        }
        catch (DbUpdateException)
        {
            if (await IsTakenAsync(phone, cancellationToken)) return CredentialErrors.PhoneTaken; // signed up concurrently
            throw;
        }
    }

    private Task<bool> IsTakenAsync(string phone, CancellationToken ct) =>
        db.Users.IgnoreQueryFilters().AsNoTracking().AnyAsync(u => u.PhoneNumber == phone, ct);

    /// <summary>Replaced on the "complete profile" step; random, so it reveals nothing about the number.</summary>
    private async Task<string> PlaceholderUsernameAsync(CancellationToken ct)
    {
        while (true)
        {
            var candidate = "reader_" + RandomNumberGenerator.GetString("abcdefghijklmnopqrstuvwxyz0123456789", 10);
            if (!await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Username == candidate, ct)) return candidate;
        }
    }

    private static string? ValidTimeZoneOrNull(string? timeZone) =>
        timeZone is not null && TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out _) ? timeZone : null;
}
