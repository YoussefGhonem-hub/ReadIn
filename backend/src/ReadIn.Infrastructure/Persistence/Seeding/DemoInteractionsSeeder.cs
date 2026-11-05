using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #8 (local only, SPEC §18.2): reactions, saves and follows by the demo users, plus a collection for reader1, so
/// feeds, the reader, the Following tab and the saved list look real in development.
/// <list type="bullet">
/// <item>Deterministic: a stable hash of (user, article) decides whether and how a demo user reacts or saves, so every
/// run and every machine seeds the same rows.</item>
/// <item>Idempotent and add-only: missing rows are added, existing ones (including your own clicks) are never changed,
/// so the counts don't move between runs. It re-runs when published articles are added (they are in the checksum).</item>
/// <item>The seeded rows raise no outbox events (no "new follower" notifications for demo data); instead the counters of
/// every article it touched are recomputed and published once at the end.</item>
/// </list>
/// </summary>
internal sealed class DemoInteractionsSeeder(AppDbContext db, ArticleCounters counters, TimeProvider clock) : ISeeder
{
    private const int ReactPercent = 30;
    private const int SavePercent = 12;
    private const int FollowPercent = 40;
    private const string MainReader = "reader1";
    private const string MainReaderCollection = "Interview prep";

    /// <summary>The demo users that interact (SPEC §18.3); the suspended account doesn't.</summary>
    private static readonly string[] Handles =
    [
        .. Enumerable.Range(1, 10).Select(i => $"reader{i}"),
        "writer1", "writer2", "writer3", "writer.verified", "reviewer.dotnet", "reviewer.ai",
    ];

    /// <summary>Demo users that write: the others follow some of them (the official ReadIn account is followed by everyone).</summary>
    private static readonly string[] Writers = ["writer.verified", "writer1", "writer2", "writer3", "reviewer.dotnet", "reviewer.ai"];

    public string Name => "demo-interactions";
    public int Order => 10;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var slugs = await PublishedArticles().Select(a => a.Slug).ToListAsync(cancellationToken);
        return SeedChecksum.Of([$"v{Version}", .. Handles, .. slugs]);
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var emails = Handles.Select(Email).ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .Select(u => new { u.Id, u.Email })
            .ToDictionaryAsync(u => u.Email!.Split('@')[0], u => u.Id, cancellationToken);
        if (users.Count == 0) return true;

        var articles = await PublishedArticles().Select(a => new { a.Id, a.Slug, a.AuthorId }).ToListAsync(cancellationToken);
        var userIds = users.Values.ToList();
        var now = clock.GetUtcNow().UtcDateTime;

        var reacted = (await db.Reactions.AsNoTracking().Where(r => userIds.Contains(r.UserId)).Select(r => new { r.UserId, r.ArticleId })
            .ToListAsync(cancellationToken)).Select(r => (r.UserId, r.ArticleId)).ToHashSet();
        var saved = (await db.SavedArticles.AsNoTracking().Where(s => userIds.Contains(s.UserId)).Select(s => new { s.UserId, s.ArticleId })
            .ToListAsync(cancellationToken)).Select(s => (s.UserId, s.ArticleId)).ToHashSet();
        var followed = (await db.UserFollows.AsNoTracking().Where(f => userIds.Contains(f.FollowerId)).Select(f => new { f.FollowerId, f.FolloweeId })
            .ToListAsync(cancellationToken)).Select(f => (f.FollowerId, f.FolloweeId)).ToHashSet();

        var created = new List<AggregateRoot>();
        var touched = new HashSet<Guid>();

        foreach (var (handle, userId) in users)
        {
            foreach (var (article, index) in articles.Select((a, i) => (a, i)))
            {
                if (article.AuthorId == userId) continue;

                var react = Hash(handle, article.Slug, "react");
                if (react % 100 < ReactPercent && reacted.Add((userId, article.Id)))
                {
                    created.Add(Reaction.Set(null, userId, article.Id, TypeFor(react), now - Spread(react)));
                    touched.Add(article.Id);
                }

                // The main demo reader always has a few saves, so the saved list and its collection are never empty.
                var save = Hash(handle, article.Slug, "save");
                var mustSave = handle == MainReader && index < 3;
                if ((mustSave || save % 100 < SavePercent) && saved.Add((userId, article.Id)))
                {
                    created.Add(SavedArticle.Create(userId, article.Id, now - Spread(save)));
                    touched.Add(article.Id);
                }
            }

            var followees = new List<Guid> { SystemUsers.EditorialId };
            followees.AddRange(Writers
                .Where(writer => writer != handle && users.ContainsKey(writer))
                .Where(writer => handle == MainReader || Hash(handle, writer, "follow") % 100 < FollowPercent)
                .Select(writer => users[writer]));
            foreach (var followeeId in followees.Where(id => followed.Add((userId, id))))
            {
                var follow = UserFollow.Create(userId, followeeId, now - Spread(Hash(handle, followeeId.ToString(), "follow")));
                if (follow.IsSuccess) created.Add(follow.Value);
            }
        }

        foreach (var aggregate in created)
        {
            aggregate.ClearDomainEvents(); // demo data: no notifications, counters recomputed below
            db.Add(aggregate);
        }
        await db.SaveChangesAsync(cancellationToken);

        await SeedMainReaderCollectionAsync(users.GetValueOrDefault(MainReader), now, cancellationToken);
        await counters.RecomputeAsync(touched, cancellationToken);
        return true;
    }

    /// <summary>reader1's "Interview prep" collection holds their two oldest saves.</summary>
    private async Task SeedMainReaderCollectionAsync(Guid userId, DateTime now, CancellationToken ct)
    {
        if (userId == Guid.Empty || await db.Collections.AnyAsync(c => c.UserId == userId, ct)) return;

        var savedIds = await db.SavedArticles.AsNoTracking()
            .Where(s => s.UserId == userId)
            .OrderBy(s => s.SavedAt).ThenBy(s => s.ArticleId)
            .Select(s => s.ArticleId)
            .Take(2)
            .ToListAsync(ct);
        if (savedIds.Count == 0) return;

        var collection = Collection.Create(userId, MainReaderCollection, existingCount: 0, now).Value;
        foreach (var articleId in savedIds) collection.AddArticle(articleId, now);
        db.Collections.Add(collection);
        await db.SaveChangesAsync(ct);
    }

    private IQueryable<Article> PublishedArticles() => db.Articles.AsNoTracking()
        .Where(a => a.Status == ArticleStatus.Published && a.Field.IsEnabled)
        .OrderBy(a => a.Slug);

    private static string Email(string handle) => $"{handle}@readin.test";

    /// <summary>Mostly 💡, then ❤️ and 🔥, a few 🤯.</summary>
    private static ReactionType TypeFor(uint hash) => (hash / 100 % 10) switch
    {
        < 5 => ReactionType.Insightful,
        < 7 => ReactionType.Love,
        < 9 => ReactionType.Fire,
        _ => ReactionType.MindBlown,
    };

    /// <summary>Spreads the timestamps over the last 30 days, so "who reacted" and the saved list have an order.</summary>
    private static TimeSpan Spread(uint hash) => TimeSpan.FromMinutes(hash % (30 * 24 * 60));

    /// <summary>Stable across runs and machines (string.GetHashCode is randomized per process).</summary>
    private static uint Hash(params string[] parts) =>
        BitConverter.ToUInt32(SHA256.HashData(Encoding.UTF8.GetBytes(string.Join('|', parts))), 0);
}
