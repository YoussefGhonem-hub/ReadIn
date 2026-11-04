using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.LearningPaths;

/// <summary>The next unread article of a user's active learning path, and its field (for F07's "not the same field 3 days in a row").</summary>
public sealed record PathNextArticle(Guid ArticleId, Guid FieldId);

/// <summary>
/// F07 "prefers the next item in the user's active learning path" (SPEC F07, F09). The active path is the enrolled,
/// unfinished one with the latest activity that still has an unread article a reader can open. Loaded for a whole batch
/// of users in a fixed number of queries.
/// </summary>
public static class ActivePathNext
{
    public static async Task<IReadOnlyDictionary<Guid, PathNextArticle>> LoadAsync(
        IAppDbContext db, IReadOnlyCollection<Guid> userIds, CancellationToken ct)
    {
        var ids = userIds.Distinct().ToList();
        var enrollments = await db.PathEnrollments.AsNoTracking()
            .Where(e => ids.Contains(e.UserId) && e.CompletedAt == null
                && db.LearningPaths.Any(p => p.Id == e.PathId && p.IsPublished
                    && db.Fields.Any(f => f.Id == p.FieldId && f.IsEnabled)))
            .Select(e => new { e.UserId, e.PathId, e.LastActivityAt })
            .ToListAsync(ct);
        if (enrollments.Count == 0) return new Dictionary<Guid, PathNextArticle>();

        var pathIds = enrollments.Select(e => e.PathId).Distinct().ToList();
        var items = await db.LearningPathItems.AsNoTracking()
            .Where(i => pathIds.Contains(i.PathId))
            .Join(db.Articles.AsNoTracking().Visible(), i => i.ArticleId, a => a.Id, (i, a) => new { i.PathId, i.Order, a.Id, a.FieldId })
            .ToListAsync(ct);
        var itemsByPath = items.ToLookup(i => i.PathId);

        var articleIds = items.Select(i => i.Id).Distinct().ToList();
        var read = (await db.ReadingProgress.AsNoTracking()
                .Where(r => ids.Contains(r.UserId) && r.CompletedAt != null && articleIds.Contains(r.ArticleId))
                .Select(r => new { r.UserId, r.ArticleId })
                .ToListAsync(ct))
            .Select(r => (r.UserId, r.ArticleId))
            .ToHashSet();

        var result = new Dictionary<Guid, PathNextArticle>();
        foreach (var user in enrollments.GroupBy(e => e.UserId))
        {
            foreach (var enrollment in user.OrderByDescending(e => e.LastActivityAt))
            {
                var next = itemsByPath[enrollment.PathId]
                    .OrderBy(i => i.Order)
                    .ThenBy(i => i.Id)
                    .FirstOrDefault(i => !read.Contains((user.Key, i.Id)));
                if (next is null) continue;
                result[user.Key] = new PathNextArticle(next.Id, next.FieldId);
                break;
            }
        }
        return result;
    }
}
