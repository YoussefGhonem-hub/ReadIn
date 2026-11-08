using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Moderation;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.ContentFilter;

/// <summary>
/// The enabled terms of the content filter, compiled once and kept in memory (SPEC F37, contract decision 9): reloaded after
/// every change in the console and every 5 minutes, so other API instances follow too.
/// </summary>
public sealed class ContentFilterCatalog
{
    public static readonly TimeSpan Refresh = TimeSpan.FromMinutes(5);

    private sealed record Snapshot(ContentFilterMatcher Matcher, int Version, DateTime LoadedAt);

    private Snapshot? _snapshot;
    private int _version;

    /// <summary>Call after the terms changed: the next check reloads them.</summary>
    public void Invalidate() => Interlocked.Increment(ref _version);

    public async Task<ContentFilterMatcher> GetAsync(IAppDbContext db, DateTime now, CancellationToken ct)
    {
        var version = Volatile.Read(ref _version);
        var current = Volatile.Read(ref _snapshot);
        if (current is not null && current.Version == version && now - current.LoadedAt < Refresh) return current.Matcher;

        var terms = await db.ContentFilterTerms.AsNoTracking()
            .Where(t => t.IsEnabled)
            .Select(t => new FilterTerm(t.NormalizedTerm, t.Language, t.Level))
            .ToListAsync(ct);
        var matcher = new ContentFilterMatcher(terms);
        Volatile.Write(ref _snapshot, new Snapshot(matcher, version, now));
        return matcher;
    }
}

/// <summary>One text a request writes, checked by the filter: its field name (for <c>422 content.objectionable</c>).</summary>
/// <param name="SpamSignals">Also look for spam signs (links, phone numbers): articles, comments, captions and bios.</param>
/// <param name="Language">An article version's language, for the editor.</param>
/// <param name="BlockId">The content block, for the editor.</param>
public sealed record ScreenedField(string Name, string? Text, bool SpamSignals = false, string? Language = null, string? BlockId = null);

/// <summary>
/// The content filter on a request's texts (SPEC F37): a block-level term refuses the request with
/// <c>422 content.objectionable</c> naming the first such field (never the word); flag-level terms and spam signs are
/// returned so the handler files a system report (F22) once the target has its id.
/// </summary>
public sealed class ContentScreening(IAppDbContext db, ContentFilterCatalog catalog, SystemReports reports, TimeProvider clock)
{
    public async Task<ContentCheck> CheckAsync(string? text, bool spamSignals, CancellationToken ct)
    {
        var matcher = await catalog.GetAsync(db, clock.GetUtcNow().UtcDateTime, ct);
        var check = matcher.Check(text);
        if (!spamSignals || check.IsBlocked) return check;
        var signals = SpamSignals.Check(text);
        return signals.Count == 0 ? check : new ContentCheck(ContentFilterLevel.Flag, [.. check.Matches, .. signals]);
    }

    /// <summary>The flagged terms of all fields, or the 422 of the first field with a block-level term.</summary>
    public async Task<Result<IReadOnlyList<string>>> ScreenAsync(IEnumerable<ScreenedField> fields, CancellationToken ct)
    {
        var flagged = new List<string>();
        foreach (var field in fields)
        {
            if (string.IsNullOrWhiteSpace(field.Text)) continue;
            var check = await CheckAsync(field.Text, field.SpamSignals, ct);
            if (check.IsBlocked) return ContentErrors.ObjectionableIn(field.Name, field.Language, field.BlockId);
            flagged.AddRange(check.Matches);
        }
        return flagged.Distinct(StringComparer.Ordinal).ToList();
    }

    /// <summary>Files (or reopens) the target's system report for <paramref name="flagged"/> terms; the caller saves.</summary>
    public Task FlagAsync(ReportTargetType targetType, Guid targetId, IReadOnlyList<string> flagged, CancellationToken ct) =>
        flagged.Count == 0 ? Task.CompletedTask : reports.FlagAsync(targetType, targetId, flagged, clock.GetUtcNow().UtcDateTime, ct);
}

/// <summary>
/// The spam limits of SPEC F37 on top of the rate limits: 5 new articles in 24 hours (an Update doesn't count) and 60
/// comments and replies an hour per account, rolling. Deleted ones still count, so deleting doesn't reset them.
/// </summary>
public sealed class ContentLimits(IAppDbContext db, TimeProvider clock)
{
    public const int ArticlesPerDay = 5;
    public const int CommentsPerHour = 60;

    /// <summary>Before a first publish.</summary>
    public async Task<Result> CheckArticleAsync(Guid authorId, CancellationToken ct)
    {
        var since = clock.GetUtcNow().UtcDateTime.AddDays(-1);
        var published = await db.Articles.IgnoreQueryFilters().CountAsync(a => a.AuthorId == authorId && a.PublishedAt >= since, ct);
        return published >= ArticlesPerDay ? ContentErrors.TooManyOf(ContentErrors.ArticlesPerDay) : Result.Success();
    }

    /// <summary>Before a new comment or reply.</summary>
    public async Task<Result> CheckCommentAsync(Guid authorId, CancellationToken ct)
    {
        var since = clock.GetUtcNow().UtcDateTime.AddHours(-1);
        var written = await db.Comments.IgnoreQueryFilters().CountAsync(c => c.AuthorId == authorId && c.CreatedAt >= since, ct);
        return written >= CommentsPerHour ? ContentErrors.TooManyOf(ContentErrors.CommentsPerHour) : Result.Success();
    }
}
