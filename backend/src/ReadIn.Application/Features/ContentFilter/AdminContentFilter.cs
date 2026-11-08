using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.ContentFilter;

public sealed record ContentFilterTermDto(
    Guid Id, string Term, string Language, string Level, string Source, bool IsEnabled, DateTime UpdatedAt);

public sealed record ContentFilterCountsDto(int Block, int Flag);

/// <summary>GET /admin/content-filter (contract <c>ContentFilterDto</c>).</summary>
public sealed record ContentFilterDto(IReadOnlyList<ContentFilterTermDto> Terms, ContentFilterCountsDto Counts);

public sealed record ContentFilterTermInput(string? Term, string? Language, string? Level);

public sealed record ContentFilterTestDto(string Level, IReadOnlyList<string> Matches);

internal static class ContentFilterValues
{
    public static readonly string[] Languages = ["ar", "en"];

    public static string LevelName(ContentFilterLevel level) => level == ContentFilterLevel.Block ? "block" : "flag";

    public static bool TryParseLevel(string? value, out ContentFilterLevel level)
    {
        level = value == "block" ? ContentFilterLevel.Block : ContentFilterLevel.Flag;
        return value is "block" or "flag";
    }

    public static async Task<ContentFilterDto> ReadAsync(IAppDbContext db, CancellationToken ct)
    {
        var rows = await db.ContentFilterTerms.AsNoTracking().ToListAsync(ct);
        var terms = rows
            .OrderBy(t => t.Language, StringComparer.Ordinal).ThenBy(t => t.Level).ThenBy(t => t.Term, StringComparer.Ordinal)
            .Select(t => new ContentFilterTermDto(
                t.Id, t.Term, t.Language, LevelName(t.Level), t.Source == ContentFilterSource.File ? "file" : "console", t.IsEnabled, t.UpdatedAt))
            .ToList();
        return new ContentFilterDto(terms, new ContentFilterCountsDto(
            rows.Count(t => t.IsEnabled && t.Level == ContentFilterLevel.Block),
            rows.Count(t => t.IsEnabled && t.Level == ContentFilterLevel.Flag)));
    }
}

/// <summary>GET /admin/content-filter: every term, enabled or not (SPEC F37; <c>system.settings</c>).</summary>
[RequirePermission(Permissions.System.Settings)]
public sealed record GetContentFilterQuery : IQuery<Result<ContentFilterDto>>;

internal sealed class GetContentFilterQueryHandler(IAppDbContext db) : IQueryHandler<GetContentFilterQuery, Result<ContentFilterDto>>
{
    public async ValueTask<Result<ContentFilterDto>> Handle(GetContentFilterQuery query, CancellationToken ct) =>
        await ContentFilterValues.ReadAsync(db, ct);
}

/// <summary>
/// PUT /admin/content-filter (SPEC F37): the whole enabled list. A term not there yet is added (the console's); a term left
/// out is disabled, so the seeder never brings a file term back; a changed level sticks. Audited
/// <c>admin.content_filter_updated</c> (<c>+added -disabled ~changed</c>); the matcher reloads at once.
/// </summary>
[RequirePermission(Permissions.System.Settings)]
public sealed record UpdateContentFilterCommand(IReadOnlyList<ContentFilterTermInput>? Terms) : ICommand<Result<ContentFilterDto>>;

internal sealed class UpdateContentFilterCommandValidator : AbstractValidator<UpdateContentFilterCommand>
{
    public UpdateContentFilterCommandValidator()
    {
        RuleFor(c => c.Terms).NotNull();
        RuleFor(c => c.Terms!.Count).LessThanOrEqualTo(ContentFilterTerm.MaxTerms).WithErrorCode("validation.max_length")
            .OverridePropertyName("terms").When(c => c.Terms is not null);
        RuleForEach(c => c.Terms).ChildRules(term =>
        {
            term.RuleFor(t => t.Term).Must(IsUsable).WithErrorCode(ContentErrors.TermInvalid);
            term.RuleFor(t => t.Language).Must(l => ContentFilterValues.Languages.Contains(l)).WithErrorCode("validation.invalid");
            term.RuleFor(t => t.Level).Must(l => ContentFilterValues.TryParseLevel(l, out _)).WithErrorCode("validation.invalid");
        }).When(c => c.Terms is not null);
    }

    /// <summary>2–100 characters after normalization, with a letter (a Franco term may hold digits too).</summary>
    public static bool IsUsable(string? term)
    {
        var normalized = ContentFilterText.NormalizeTerm(term);
        return normalized.Length is >= ContentFilterTerm.MinLength and <= ContentFilterTerm.MaxLength && normalized.Any(char.IsLetter);
    }
}

internal sealed class UpdateContentFilterCommandHandler(
    IAppDbContext db, ContentFilterCatalog catalog, AuditTrail audit, TimeProvider clock)
    : ICommandHandler<UpdateContentFilterCommand, Result<ContentFilterDto>>
{
    public async ValueTask<Result<ContentFilterDto>> Handle(UpdateContentFilterCommand command, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        // One entry per normalized term; a block level wins over a flag for the same term.
        var wanted = new Dictionary<string, (string Term, string Language, ContentFilterLevel Level)>(StringComparer.Ordinal);
        foreach (var input in command.Terms!)
        {
            ContentFilterValues.TryParseLevel(input.Level, out var level);
            var key = ContentFilterText.NormalizeTerm(input.Term);
            if (wanted.TryGetValue(key, out var existing) && existing.Level == ContentFilterLevel.Block) continue;
            wanted[key] = (input.Term!.Trim(), input.Language!, level);
        }

        var rows = await db.ContentFilterTerms.ToDictionaryAsync(t => t.NormalizedTerm, StringComparer.Ordinal, ct);
        int added = 0, disabled = 0, changed = 0;
        foreach (var (key, term) in wanted)
        {
            if (rows.TryGetValue(key, out var row))
            {
                var wasEnabled = row.IsEnabled;
                if (row.SetByAdmin(term.Level, isEnabled: true, now))
                {
                    if (wasEnabled) changed++;
                    else added++;
                }
                continue;
            }
            db.ContentFilterTerms.Add(new ContentFilterTerm(term.Term, key, term.Language, term.Level, ContentFilterSource.Console, now));
            added++;
        }
        foreach (var row in rows.Values.Where(r => r.IsEnabled && !wanted.ContainsKey(r.NormalizedTerm)))
        {
            row.SetByAdmin(row.Level, isEnabled: false, now);
            disabled++;
        }

        if (added + disabled + changed > 0)
        {
            audit.Record(AuditActions.ContentFilterUpdated, null, null, null, $"+{added} -{disabled} ~{changed}");
            await db.SaveChangesAsync(ct);
            catalog.Invalidate();
        }
        return await ContentFilterValues.ReadAsync(db, ct);
    }
}

/// <summary>POST /admin/content-filter/test: what the filter makes of a text, with the matched terms (staff only).</summary>
[RequirePermission(Permissions.System.Settings)]
public sealed record TestContentFilterQuery(string? Text) : IQuery<Result<ContentFilterTestDto>>;

internal sealed class TestContentFilterQueryValidator : AbstractValidator<TestContentFilterQuery>
{
    public TestContentFilterQueryValidator() => RuleFor(q => q.Text).NotEmpty().MaximumLength(5000);
}

internal sealed class TestContentFilterQueryHandler(ContentScreening screening)
    : IQueryHandler<TestContentFilterQuery, Result<ContentFilterTestDto>>
{
    public async ValueTask<Result<ContentFilterTestDto>> Handle(TestContentFilterQuery query, CancellationToken ct)
    {
        var check = await screening.CheckAsync(query.Text, spamSignals: true, ct);
        var level = check.Level switch
        {
            ContentFilterLevel.Block => "block",
            ContentFilterLevel.Flag => "flag",
            _ => "none",
        };
        return new ContentFilterTestDto(level, check.Matches);
    }
}
