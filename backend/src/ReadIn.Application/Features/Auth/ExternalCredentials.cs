using System.Security.Cryptography;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth;

internal sealed class ExternalCredentialValidator : AbstractValidator<ExternalCredentialDto>
{
    public const string ProviderInvalid = "provider.invalid";

    public ExternalCredentialValidator()
    {
        RuleFor(c => c.Provider).Must(ExternalProviders.IsKnown).WithErrorCode(ProviderInvalid);
        RuleFor(c => c.IdToken).NotEmpty().Unless(IsGoogleCode).MaximumLength(8192);
        RuleFor(c => c.Nonce).MaximumLength(256);
        RuleFor(c => c.AuthorizationCode).MaximumLength(1024);
    }

    /// <summary>Google's web code flow: a code and no ID token (ADR 0012).</summary>
    private static bool IsGoogleCode(ExternalCredentialDto c) =>
        c.Provider == ExternalProviders.Google && string.IsNullOrEmpty(c.IdToken) && !string.IsNullOrEmpty(c.AuthorizationCode);
}

/// <summary>
/// Checks what a client sent for Google or Apple (SPEC §9.1): the provider's ID token, or, from the web's own Google button,
/// a Google authorization code that is first traded for the ID token (ADR 0012). Either way the same token checks run.
/// </summary>
internal sealed class ExternalCredentialVerifier(IExternalIdentityVerifier identities, IGoogleCodeExchanger googleCodes)
{
    public Task<Result<ExternalIdentity>> VerifyAsync(ExternalCredentialDto credential, CancellationToken ct) =>
        VerifyAsync(credential.Provider, credential.IdToken, credential.Nonce, credential.AuthorizationCode, ct);

    public async Task<Result<ExternalIdentity>> VerifyAsync(
        string provider, string? idToken, string? nonce, string? authorizationCode, CancellationToken ct)
    {
        if (string.IsNullOrEmpty(idToken))
        {
            if (provider != ExternalProviders.Google || string.IsNullOrEmpty(authorizationCode)) return CredentialErrors.ExternalInvalid;
            if (!identities.EnabledProviders.Contains(provider)) return CredentialErrors.ProviderDisabled;

            var exchanged = await googleCodes.ExchangeAsync(authorizationCode, ct);
            if (exchanged.IsFailure) return exchanged.Error;
            idToken = exchanged.Value;
        }
        return await identities.VerifyAsync(provider, idToken, nonce, ct);
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
