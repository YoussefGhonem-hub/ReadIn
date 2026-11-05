using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Local only (SPEC §18.2 step 9, §18.3): a few comment threads so F11 looks alive in development. Mixed Arabic and
/// English, replies, @mentions, likes, a pinned comment, a deleted comment kept as a placeholder for its reply, and a spam
/// comment hidden by the demo SuperAdmin after a report. They go on the four most-read of @readin's articles, the only
/// seeded articles (SPEC §18.1); demo users write comments, never articles. Writes SQL only: no domain events, so nothing
/// reaches the Realtime Database, and the counters are recomputed here. A re-run replaces the demo users' comments on those
/// articles, and its own comments wherever they are (they are found by their text).
/// </summary>
internal sealed class DemoCommentsSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    /// <param name="Author">Demo user handle.</param>
    /// <param name="HoursAgo">How long ago it was written.</param>
    /// <param name="Likers">Handles that like it.</param>
    private sealed record DemoComment(string Author, string Body, double HoursAgo, string[]? Likers = null, DemoComment[]? Replies = null,
        bool Deleted = false, bool HiddenAsSpam = false, bool Pinned = false);

    private sealed record DemoThread(ArticlePick Article, DemoComment[] Comments);

    /// <summary>@readin's published articles by read count: the first, second, third and fourth.</summary>
    private enum ArticlePick
    {
        MostRead,
        SecondMostRead,
        ThirdMostRead,
        FourthMostRead,
    }

    private static readonly DemoThread[] Threads =
    [
        new(ArticlePick.MostRead,
        [
            new("reader1", "شرح واضح جدًا، خصوصًا الجزء بتاع الأمثلة. ياريت مقال تاني عن الـ edge cases 👏", 50,
                ["reader2", "reader3", "reader6", "writer2", "reviewer.dotnet", "reader9"],
            [
                new("writer2", "متفق، والمثال التاني فرق معايا كتير في الشغل.", 48, ["reader1"]),
                new("reader3", "@reader1 لو عايز تتعمق أكتر فيه روابط كويسة في الـ Sources تحت.", 46, ["reader1", "reader4"]),
            ]),
            new("reader4", "Great read. The comparison at the end is exactly what I needed for my team's review.", 30,
                ["reader1", "writer3", "reader6"]),
            new("reader5", "عندي سؤال: هل الكلام ده بيفرق لو الـ project كبير وفيه فريق كبير؟", 20, ["reader2"],
            [
                new("reviewer.dotnet", "@reader5 أيوه، في المشاريع الكبيرة الفرق بيبان أكتر لأن الـ conventions بتوفر وقت review كتير.", 18,
                    ["reader5", "reader1", "reader4"]),
            ]),
            new("reader8", "سؤال اتمسح", 12, Deleted: true, Replies:
            [
                new("reader9", "كان في سؤال حلو هنا 😅 بس الإجابة في الفقرة التالتة.", 11),
            ]),
        ]),
        new(ArticlePick.SecondMostRead,
        [
            new("writer3", "Nice summary. I'd add that monitoring matters as much as the setup itself.", 40, ["reader2", "reader6"],
            [
                new("reader2", "+1، وده اللي بيفرق في الـ production فعلًا.", 38),
            ]),
            new("reader6", "قريته امبارح ورجعتله تاني النهارده، مفيد جدًا 🔥", 9, ["reader1", "reader7"]),
            new("reader7", "Check my channel for FREE courses!!! link in bio", 6, HiddenAsSpam: true),
        ]),
        new(ArticlePick.ThirdMostRead,
        [
            new("reader2", "Is there a follow-up to this one? The example in the middle is exactly what I was missing.", 70,
                ["reader1", "reader3", "writer2"], Pinned: true,
                Replies:
                [
                    new("writer1", "@reader2 the sources at the end go deeper, the second one especially.", 69, ["reader2", "reader1"]),
                    new("reader2", "شكرًا @writer1، لقيته 🙏", 67, ["writer1"]),
                ]),
            new("reader1", "قريته مرتين، الشرح بالأمثلة بيفرق جدًا", 60, ["writer1"],
            [
                new("writer1", "فعلًا، وجربت الكلام ده في مشروع عندي ونفع 😄", 58, ["reader1"]),
            ]),
        ]),
        new(ArticlePick.FourthMostRead,
        [
            new("reviewer.dotnet", "الجزء بتاع الـ trade-offs في الآخر بيلخص الفكرة كلها 👌", 26, ["writer3", "reader4"],
            [
                new("reader4", "متفق، وده اللي بيفرق في الـ code review.", 25, ["reviewer.dotnet"]),
            ]),
        ]),
    ];

    public string Name => "demo-comments";
    public int Order => 11;
    public int Version => 3; // 3: on @readin's articles only (no demo posts any more)

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of([.. Threads.SelectMany(t => Flatten(t.Comments)).Select(c =>
            $"{c.Author}|{c.Body}|{c.HoursAgo}|{string.Join(',', c.Likers ?? [])}|{c.Deleted}|{c.HiddenAsSpam}|{c.Pinned}")]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var handles = Threads.SelectMany(t => Flatten(t.Comments)).SelectMany(c => (c.Likers ?? []).Append(c.Author)).Distinct().ToList();
        var emails = handles.Select(h => $"{h}@readin.test").ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => u.Id, cancellationToken);
        // The SuperAdmin moderates (SPEC §10): seeded by the system accounts seeder before this one.
        var moderatorId = SystemUsers.SuperAdminId;
        if (!await db.Users.AnyAsync(u => u.Id == moderatorId, cancellationToken)) return true;

        var articles = await PickArticlesAsync(cancellationToken);
        var demoUserIds = users.Values.ToList();
        var articleIds = articles.Values.ToList();

        // Replace the demo users' comments on these articles, and this seeder's own comments wherever an earlier run put them
        // (the picks follow the read counts); likes, mentions and their reports go with them.
        var bodies = Threads.SelectMany(t => Flatten(t.Comments)).Select(c => c.Body).Distinct().ToList();
        var replaced = await db.Comments.IgnoreQueryFilters()
            .Where(c => c.AuthorId != null && demoUserIds.Contains(c.AuthorId.Value) && (articleIds.Contains(c.ArticleId) || bodies.Contains(c.Body)))
            .Select(c => new { c.Id, c.ArticleId }).ToListAsync(cancellationToken);
        var old = replaced.Select(c => c.Id).ToList();
        var recounted = articleIds.Union(replaced.Select(c => c.ArticleId)).ToList();
        await db.Reports.Where(r => r.TargetType == ReportTargetType.Comment && old.Contains(r.TargetId)).ExecuteDeleteAsync(cancellationToken);
        // Notifications about them (F17; the key doesn't cascade).
        await db.Notifications.Where(n => n.CommentId != null && old.Contains(n.CommentId.Value)).ExecuteDeleteAsync(cancellationToken);
        await db.Comments.IgnoreQueryFilters().Where(c => old.Contains(c.Id)).ExecuteDeleteAsync(cancellationToken);

        var createdAt = new Dictionary<Comment, DateTime>();
        var likes = new List<(Comment Comment, Guid UserId, DateTime At)>();
        var hidden = new List<Comment>();
        foreach (var thread in Threads)
        {
            if (!articles.TryGetValue(thread.Article, out var articleId)) continue;
            foreach (var demo in thread.Comments)
            {
                if (!users.TryGetValue(demo.Author, out var authorId)) continue;
                var at = now.AddHours(-demo.HoursAgo);
                var comment = Comment.Post(articleId, authorId, demo.Body, Mentions(demo.Body, users), at);
                db.Comments.Add(comment);
                Collect(comment, demo, at);

                foreach (var reply in demo.Replies ?? [])
                {
                    if (!users.TryGetValue(reply.Author, out var replierId)) continue;
                    var replyAt = now.AddHours(-reply.HoursAgo);
                    var posted = Comment.Reply(comment, replierId, reply.Body, Mentions(reply.Body, users), replyAt).Value;
                    db.Comments.Add(posted);
                    Collect(posted, reply, replyAt);
                }

                if (demo.Pinned) comment.Pin(at);
                // Deleted after its replies were posted: the placeholder that keeps them.
                if (demo.Deleted) comment.Delete(authorId, at.AddHours(1));
                if (demo.HiddenAsSpam)
                {
                    hidden.Add(comment);
                    comment.Hide(moderatorId, at.AddHours(1));
                }
            }
        }
        await SaveWithoutEventsAsync(cancellationToken);

        db.CommentLikes.AddRange(likes.Select(l => CommentLike.Create(l.Comment, l.UserId, l.At)));
        if (users.TryGetValue("reader1", out var reporterId))
        {
            foreach (var comment in hidden)
                db.Reports.Add(Report.File(ReportTargetType.Comment, comment.Id, reporterId, ReportReason.Spam, null, now.AddHours(-5)));
        }
        await SaveWithoutEventsAsync(cancellationToken);

        // Comment times (the auditing interceptor stamps "now" on insert) and the counts.
        foreach (var (comment, at) in createdAt)
        {
            await db.Comments.IgnoreQueryFilters().Where(c => c.Id == comment.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.CreatedAt, at), cancellationToken);
        }
        await db.Comments.IgnoreQueryFilters().Where(c => recounted.Contains(c.ArticleId))
            .ExecuteUpdateAsync(s => s
                .SetProperty(c => c.LikeCount, c => db.CommentLikes.Count(l => l.CommentId == c.Id))
                .SetProperty(c => c.ReplyCount, c => db.Comments.Count(r => r.ParentId == c.Id && !r.IsDeleted && r.HiddenAt == null)),
                cancellationToken);
        await db.Articles.IgnoreQueryFilters().Where(a => recounted.Contains(a.Id))
            .ExecuteUpdateAsync(s => s.SetProperty(a => a.CommentCount,
                a => db.Comments.Count(c => c.ArticleId == a.Id && !c.IsDeleted && c.HiddenAt == null)), cancellationToken);
        return true;

        void Collect(Comment comment, DemoComment demo, DateTime at)
        {
            createdAt[comment] = at;
            foreach (var liker in demo.Likers ?? [])
                if (users.TryGetValue(liker, out var likerId)) likes.Add((comment, likerId, at.AddMinutes(30)));
        }
    }

    /// <summary>Demo data never goes through the outbox, so it never reaches the Realtime Database.</summary>
    private Task SaveWithoutEventsAsync(CancellationToken ct)
    {
        foreach (var entry in db.ChangeTracker.Entries<Domain.Common.AggregateRoot>()) entry.Entity.ClearDomainEvents();
        return db.SaveChangesAsync(ct);
    }

    /// <summary>@readin's most-read published articles, one per pick (fewer when there are fewer articles).</summary>
    private async Task<Dictionary<ArticlePick, Guid>> PickArticlesAsync(CancellationToken ct)
    {
        var mostRead = await db.Articles.AsNoTracking()
            .Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status == ArticleStatus.Published && a.HiddenAt == null)
            .OrderByDescending(a => a.ReadCount).ThenBy(a => a.Slug)
            .Select(a => a.Id).Take(Enum.GetValues<ArticlePick>().Length).ToListAsync(ct);
        return mostRead.Select((id, i) => (Pick: (ArticlePick)i, Id: id)).ToDictionary(p => p.Pick, p => p.Id);
    }

    private static IReadOnlyCollection<Guid> Mentions(string body, IReadOnlyDictionary<string, Guid> users) =>
        [.. CommentText.MentionedUsernames(body).Select(u => users.TryGetValue(u, out var id) ? id : Guid.Empty).Where(id => id != Guid.Empty)];

    private static IEnumerable<DemoComment> Flatten(IEnumerable<DemoComment> comments) =>
        comments.SelectMany(c => (c.Replies ?? []).Prepend(c));
}
