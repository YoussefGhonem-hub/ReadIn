using System.Security.Cryptography;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth;

internal sealed class ExternalCredentialValidator : AbstractValidator<ExternalCredentialDto>
{
    public const string ProviderInvalid = "provider.invalid";

    public ExternalCredentialValidator()
    {
        RuleFor(c => c.Provider).Must(ExternalProviders.IsKnown).WithErrorCode(ProviderInvalid);
        RuleFor(c => c.IdToken).NotEmpty().MaximumLength(8192);
        RuleFor(c => c.Nonce).MaximumLength(256);
    }
}

/// <summary>Defaults for a new account, shared by phone and Google/Apple sign up (SPEC §9.2).</summary>
internal static class NewAccounts
{
    /// <summary>Replaced on the "complete profile" step; random, so it reveals nothing about the person.</summary>
    public static async Task<string> PlaceholderUsernameAsync(IAppDbContext db, CancellationToken ct)
    {
        while (true)
        {
            var candidate = "reader_" + RandomNumberGenerator.GetString("abcdefghijklmnopqrstuvwxyz0123456789", 10);
            if (!await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Username == candidate, ct)) return candidate;
        }
    }

    public static string? ValidTimeZoneOrNull(string? timeZone) =>
        timeZone is not null && TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out _) ? timeZone : null;
}
