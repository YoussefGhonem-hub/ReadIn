using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Legal;

/// <summary>The Terms of Use version every account must accept (SPEC F37), and what the terms screen says changed.</summary>
public sealed class LegalOptions
{
    public const string Section = "Legal";
    public const int MaxVersionLength = 16;

    /// <summary>A date-like version, e.g. <c>2026-11-08</c>. Raising it shows signed-in people the terms screen once.</summary>
    public string TermsVersion { get; set; } = "2026-11-08";

    /// <summary>When the version took effect; optional.</summary>
    public DateTime? EffectiveAt { get; set; }

    public LegalSummaryOptions Summary { get; set; } = new();
}

public sealed class LegalSummaryOptions
{
    public string? Ar { get; set; }
    public string? En { get; set; }
}

public sealed record LegalSummaryDto(string? Ar, string? En);

public sealed record LegalPagesDto(string Terms, string CommunityGuidelines, string Privacy);

/// <summary>GET /legal (contract <c>LegalDto</c>): paths on the web; clients prepend their web origin.</summary>
public sealed record LegalDto(string TermsVersion, DateTime? EffectiveAt, LegalSummaryDto Summary, LegalPagesDto Pages);

public static class LegalErrors
{
    /// <summary>Sign up without ticking the terms box (SPEC §9.2, F37).</summary>
    public static readonly Error TermsRequired =
        Error.Validation("auth.terms_required", "You must agree to the Terms of Use and Community Guidelines to create an account.");
}

/// <summary>The terms an account must have accepted (SPEC F37): sign up records them; a newer version asks again.</summary>
public sealed class TermsOfUse(IOptions<LegalOptions> options)
{
    public string CurrentVersion => options.Value.TermsVersion;

    /// <summary>Whether the account must see the terms screen: it accepted none, or an older version.</summary>
    public bool MustAccept(string? acceptedVersion) => acceptedVersion != CurrentVersion;

    /// <summary><c>400 auth.terms_required</c> unless the box was ticked.</summary>
    public static Result Require(bool? acceptTerms) => acceptTerms == true ? Result.Success() : LegalErrors.TermsRequired;
}

/// <summary>GET /legal: the current terms version and the legal pages (anonymous).</summary>
public sealed record GetLegalQuery : IQuery<Result<LegalDto>>;

internal sealed class GetLegalQueryHandler(IOptions<LegalOptions> options) : IQueryHandler<GetLegalQuery, Result<LegalDto>>
{
    public ValueTask<Result<LegalDto>> Handle(GetLegalQuery query, CancellationToken cancellationToken)
    {
        var legal = options.Value;
        Result<LegalDto> result = new LegalDto(
            legal.TermsVersion,
            legal.EffectiveAt,
            new LegalSummaryDto(Blank(legal.Summary.Ar), Blank(legal.Summary.En)),
            new LegalPagesDto("/terms", "/community-guidelines", "/privacy"));
        return ValueTask.FromResult(result);
    }

    private static string? Blank(string? text) => string.IsNullOrWhiteSpace(text) ? null : text.Trim();
}

/// <summary>
/// POST /me/terms/accept (SPEC F37): accepts the current version now; idempotent. Audited <c>auth.terms_accepted</c> with
/// the version. Returns the refreshed <see cref="MeDto"/> (<c>mustAcceptTerms: false</c>).
/// </summary>
[Authenticated]
public sealed record AcceptTermsCommand : ICommand<Result<MeDto>>;

internal sealed class AcceptTermsCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, TermsOfUse terms, AuditTrail audit, MeReader me, TimeProvider clock)
    : ICommandHandler<AcceptTermsCommand, Result<MeDto>>
{
    public async ValueTask<Result<MeDto>> Handle(AcceptTermsCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
        if (user is null) return UserErrors.NotFound;

        if (user.AcceptTerms(terms.CurrentVersion, clock.GetUtcNow().UtcDateTime))
        {
            audit.Record(AuditActions.TermsAccepted, user.Id, AuditTargets.User, user.Id, terms.CurrentVersion);
            await db.SaveChangesAsync(cancellationToken);
        }
        return await me.ReadAsync(user.Id, cancellationToken);
    }
}
