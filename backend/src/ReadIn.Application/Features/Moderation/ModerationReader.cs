using System.Globalization;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Moderation;

public readonly record struct ModerationTargetKey(ReportTargetType Type, Guid Id);

/// <summary>
/// Builds what the moderation queue, a case and the log show (SPEC F22), a fixed number of queries per page. Moderators see
/// deleted and hidden targets too, so these reads ignore the soft-delete filters.
/// </summary>
public sealed class ModerationReader(IAppDbContext db, IFileStorage storage, TimeProvider clock)
{
    /// <summary>A target that no longer exists (or a deleted account).</summary>
    private static readonly ModerationTargetDto Gone = new() { State = ModerationTargetStates.Deleted };

    private sealed record ArticleRow(Guid Id, string Slug, string Language, Guid? AuthorId, bool IsDeleted, DateTime? HiddenAt, string? Title);

    private sealed record CommentRow(Guid Id, string Body, Guid ArticleId, Guid? AuthorId, bool IsDeleted, DateTime? HiddenAt);

    private sealed record UserRow(
        Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified, bool IsDeleted, bool IsSuspended, DateTime? SuspendedUntil,
        string? Headline, IReadOnlyList<ProfileLink> Links);

    public async Task<IReadOnlyDictionary<ModerationTargetKey, ModerationTargetDto>> TargetsAsync(
        IReadOnlyCollection<ModerationTargetKey> keys, CancellationToken ct)
    {
        var commentIds = IdsOf(keys, ReportTargetType.Comment);
        var comments = commentIds.Count == 0
            ? []
            : await db.Comments.IgnoreQueryFilters().AsNoTracking()
                .Where(c => commentIds.Contains(c.Id))
                .Select(c => new CommentRow(c.Id, c.Body, c.ArticleId, c.AuthorId, c.IsDeleted, c.HiddenAt))
                .ToListAsync(ct);

        var articleIds = IdsOf(keys, ReportTargetType.Article).Concat(comments.Select(c => c.ArticleId)).Distinct().ToList();
        var articles = articleIds.Count == 0
            ? new Dictionary<Guid, ArticleRow>()
            : await db.Articles.IgnoreQueryFilters().AsNoTracking()
                .Where(a => articleIds.Contains(a.Id))
                .Select(a => new ArticleRow(a.Id, a.Slug, a.SourceLanguage, a.AuthorId, a.IsDeleted, a.HiddenAt,
                    a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault()))
                .ToDictionaryAsync(a => a.Id, ct);

        var userTargets = IdsOf(keys, ReportTargetType.User);
        var people = articles.Values.Select(a => (Guid?)a.AuthorId).Concat(comments.Select(c => c.AuthorId))
            .OfType<Guid>().Concat(userTargets).Distinct().ToList();
        var users = people.Count == 0
            ? new Dictionary<Guid, UserRow>()
            : await db.Users.IgnoreQueryFilters().AsNoTracking()
                .Where(u => people.Contains(u.Id))
                .Select(u => new UserRow(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified,
                    u.IsDeleted, u.IsSuspended, u.SuspendedUntil, u.Headline, u.Links))
                .ToDictionaryAsync(u => u.Id, ct);
        var warnings = userTargets.Count == 0
            ? new Dictionary<Guid, int>()
            : await db.ModerationActions.AsNoTracking()
                .Where(m => m.Action == ModerationActionTypes.UserWarn && m.TargetType == ReportTargetType.User && userTargets.Contains(m.TargetId))
                .GroupBy(m => m.TargetId)
                .Select(g => new { UserId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(g => g.UserId, g => g.Count, ct);

        var commentsById = comments.ToDictionary(c => c.Id);
        var now = clock.GetUtcNow().UtcDateTime;
        return keys.Distinct().ToDictionary(key => key, key => key.Type switch
        {
            ReportTargetType.Article => articles.TryGetValue(key.Id, out var article)
                ? new ModerationTargetDto
                {
                    State = ContentState(article.IsDeleted, article.HiddenAt),
                    Author = Author(article.AuthorId),
                    Title = article.Title,
                    Slug = article.Slug,
                    Language = article.Language,
                }
                : Gone,
            ReportTargetType.Comment => commentsById.TryGetValue(key.Id, out var comment)
                ? new ModerationTargetDto
                {
                    State = ContentState(comment.IsDeleted, comment.HiddenAt),
                    Author = Author(comment.AuthorId),
                    Body = comment.Body,
                    ArticleId = comment.ArticleId,
                    ArticleSlug = articles.GetValueOrDefault(comment.ArticleId)?.Slug,
                    ArticleTitle = articles.GetValueOrDefault(comment.ArticleId)?.Title,
                }
                : Gone,
            _ => users.TryGetValue(key.Id, out var user) && !user.IsDeleted
                ? new ModerationTargetDto
                {
                    State = SuspendedAt(user, now) ? ModerationTargetStates.Suspended : ModerationTargetStates.Active,
                    Author = Author(user.Id),
                    SuspendedUntil = SuspendedAt(user, now) ? user.SuspendedUntil : null,
                    WarningCount = warnings.GetValueOrDefault(user.Id),
                    // F14: what clear_links removes; the title (clear_headline) is Author.Headline.
                    Links = user.Links.ToDtos(),
                }
                : Gone with { WarningCount = warnings.GetValueOrDefault(key.Id) },
        });

        AuthorDto? Author(Guid? id) =>
            id is { } userId && users.TryGetValue(userId, out var u) && !u.IsDeleted
                ? new AuthorDto(u.Id, u.DisplayName, u.Username, storage.ToPublicUrl(u.AvatarUrl), u.IsVerified, u.Headline)
                : null;
    }

    /// <summary>User summaries by id; deleted users are left out (they show as null).</summary>
    public async Task<IReadOnlyDictionary<Guid, UserSummaryDto>> SummariesAsync(IEnumerable<Guid?> ids, CancellationToken ct)
    {
        var wanted = ids.OfType<Guid>().Distinct().ToList();
        if (wanted.Count == 0) return new Dictionary<Guid, UserSummaryDto>();

        var users = await db.Users.AsNoTracking()
            .Where(u => wanted.Contains(u.Id))
            .Select(UserSummaries.For(db, viewerId: null))
            .ToListAsync(ct);
        return users.ToDictionary(u => u.Id, u => u.WithPublicUrls(storage));
    }

    public async Task<List<ModerationActionDto>> ActionsAsync(IReadOnlyList<ModerationAction> rows, CancellationToken ct)
    {
        var users = await SummariesAsync(rows.SelectMany(r => new[] { r.TargetUserId, r.ModeratorId }), ct);
        return
        [
            .. rows.Select(r => new ModerationActionDto(
                r.Id, r.Action, r.TargetType, r.TargetId, r.TargetLabel,
                Find(users, r.TargetUserId), Find(users, r.ModeratorId),
                r.Note, r.SuspendedUntil, r.ReportsClosed, r.CreatedAt)),
        ];
    }

    public static UserSummaryDto? Find(IReadOnlyDictionary<Guid, UserSummaryDto> users, Guid? id) =>
        id is { } value ? users.GetValueOrDefault(value) : null;

    /// <summary><c>{ "spam": 2, "other": 1 }</c>, in the reasons' order.</summary>
    public static IReadOnlyDictionary<string, int> Reasons(IEnumerable<(ReportReason Reason, int Count)> counts) =>
        counts.Where(c => c.Count > 0)
            .OrderBy(c => c.Reason)
            .ToDictionary(c => JsonNamingPolicy.CamelCase.ConvertName(c.Reason.ToString()), c => c.Count);

    private static List<Guid> IdsOf(IEnumerable<ModerationTargetKey> keys, ReportTargetType type) =>
        [.. keys.Where(k => k.Type == type).Select(k => k.Id).Distinct()];

    private static string ContentState(bool isDeleted, DateTime? hiddenAt) =>
        isDeleted ? ModerationTargetStates.Deleted : hiddenAt is null ? ModerationTargetStates.Visible : ModerationTargetStates.Hidden;

    private static bool SuspendedAt(UserRow user, DateTime now) => user.IsSuspended && (user.SuspendedUntil is null || user.SuspendedUntil > now);
}

/// <summary>Parses the target types, statuses and reasons of requests: names in any case, never numbers.</summary>
internal static class ModerationValues
{
    public static bool TryParseTarget(string? value, out ReportTargetType type) => TryParse(value, out type);

    public static bool TryParseStatus(string? value, out ReportStatus status) => TryParse(value, out status);

    public static bool TryParseReason(string? value, out ReportReason reason) => TryParse(value, out reason);

    private static bool TryParse<T>(string? value, out T result) where T : struct, Enum =>
        Enum.TryParse(value, ignoreCase: true, out result) && !int.TryParse(value, out _) && Enum.IsDefined(result);
}

/// <summary>
/// Opaque keyset cursor of the queue: the open list pages by (report count DESC, last report DESC, target id DESC),
/// the resolved and dismissed lists by (closed at DESC, target id DESC) with a count of 0.
/// </summary>
internal readonly record struct QueueCursor(int Count, DateTime At, Guid Id)
{
    public string Encode() =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(
                $"{Count.ToString(CultureInfo.InvariantCulture)}:{At.Ticks.ToString(CultureInfo.InvariantCulture)}:{Id:N}"))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static QueueCursor? Decode(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return null;
        try
        {
            var base64 = cursor.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '=');
            var parts = Encoding.UTF8.GetString(Convert.FromBase64String(base64)).Split(':');
            if (parts.Length != 3) return null;
            return new QueueCursor(
                int.Parse(parts[0], CultureInfo.InvariantCulture),
                new DateTime(long.Parse(parts[1], CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(parts[2], "N"));
        }
        catch (Exception ex) when (ex is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
