using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Realtime;

/// <summary>
/// Keeps <c>/live/articles/{id}/events</c> small (SPEC §21.2): events older than 24 hours go, and at most 100 stay per
/// article. Clients only listen from "now", so old events are never read. Events are only written for comment changes,
/// so the articles to check come from SQL: those with comment activity in the last <see cref="ActivityWindow"/>. Runs
/// hourly; when the Realtime Database isn't configured it does nothing.
/// </summary>
internal sealed partial class LiveEventsCleanupJob(
    AppDbContext db,
    RealtimeDatabaseClient database,
    IOptions<FirebaseOptions> options,
    TimeProvider clock,
    ILogger<LiveEventsCleanupJob> logger)
{
    public const int MaxEventsPerArticle = 100;
    public static readonly TimeSpan KeepFor = TimeSpan.FromHours(24);

    /// <summary>Wider than <see cref="KeepFor"/>, so a few failed runs still get to every article.</summary>
    public static readonly TimeSpan ActivityWindow = TimeSpan.FromDays(3);

    public async Task RunAsync(CancellationToken cancellationToken)
    {
        if (options.Value.RealtimeDatabaseBaseUrl is null) return;

        var now = clock.GetUtcNow().UtcDateTime;
        var since = now - ActivityWindow;
        var comments = db.Comments.IgnoreQueryFilters().AsNoTracking();
        var articleIds = await comments
            .Where(c => c.CreatedAt >= since || c.UpdatedAt >= since || c.DeletedAt >= since)
            .Select(c => c.ArticleId)
            .Union(db.CommentLikes.AsNoTracking().Where(l => l.LikedAt >= since)
                .Join(comments, l => l.CommentId, c => c.Id, (l, c) => c.ArticleId))
            .ToListAsync(cancellationToken);

        var removed = 0;
        foreach (var articleId in articleIds)
        {
            var path = $"live/articles/{articleId}/events";
            var keys = await database.GetKeysAsync(path, cancellationToken);
            if (keys is null) continue; // RTDB unreachable: the next run tries again

            var expired = Expired(keys, now);
            if (expired.Count > 0 && await database.DeleteChildrenAsync(path, expired, cancellationToken)) removed += expired.Count;
        }

        if (removed > 0) LogRemoved(logger, removed, articleIds.Count);
    }

    /// <summary>Keys to delete: older than <see cref="KeepFor"/>, or beyond the newest <see cref="MaxEventsPerArticle"/>.</summary>
    internal static IReadOnlyList<string> Expired(IEnumerable<string> keys, DateTime now)
    {
        var cutoff = now - KeepFor;
        // Push ids sort in creation order, so the newest are last.
        var ordered = keys.Order(StringComparer.Ordinal).ToList();
        var overflow = Math.Max(0, ordered.Count - MaxEventsPerArticle);
        return [.. ordered.Where((key, index) => index < overflow || PushIds.CreatedAt(key) is not { } at || at < cutoff)];
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Removed {Count} old live events across {Articles} articles")]
    private static partial void LogRemoved(ILogger logger, int count, int articles);
}

/// <summary>Firebase push ids: the first 8 characters are the creation time in ms, in Firebase's base-64 alphabet.</summary>
internal static class PushIds
{
    private const string Alphabet = "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";

    /// <summary>Null for a key that isn't a push id; the cleanup job removes those too.</summary>
    public static DateTime? CreatedAt(string key)
    {
        if (key.Length < 8) return null;
        long ms = 0;
        for (var i = 0; i < 8; i++)
        {
            var digit = Alphabet.IndexOf(key[i], StringComparison.Ordinal);
            if (digit < 0) return null;
            ms = ms * 64 + digit;
        }
        return DateTime.UnixEpoch.AddMilliseconds(ms);
    }

    /// <summary>The time prefix of a push id created at <paramref name="at"/> (tests).</summary>
    public static string Prefix(DateTime at)
    {
        var ms = (long)(at - DateTime.UnixEpoch).TotalMilliseconds;
        var chars = new char[8];
        for (var i = 7; i >= 0; i--)
        {
            chars[i] = Alphabet[(int)(ms % 64)];
            ms /= 64;
        }
        return new string(chars);
    }
}
