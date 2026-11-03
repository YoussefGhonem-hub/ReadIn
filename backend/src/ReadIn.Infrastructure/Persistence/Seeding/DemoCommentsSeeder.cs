using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Local only (SPEC §18.2 step 8, §18.3): a few comment threads so F11 looks alive in development. Mixed Arabic and
/// English, replies, @mentions, likes, a writer replying with the "الكاتب" badge, a pinned comment, a deleted comment
/// kept as a placeholder for its reply, and a spam comment hidden by the moderator after a report. They go on the two
/// most-read articles and the two demo media posts. Writes SQL only: no domain events, so nothing reaches the Realtime
/// Database, and the counters are recomputed here. A re-run replaces the demo users' comments on those articles.
/// </summary>
internal sealed class DemoCommentsSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    /// <param name="Author">Demo user handle.</param>
    /// <param name="HoursAgo">How long ago it was written.</param>
    /// <param name="Likers">Handles that like it.</param>
    private sealed record DemoComment(string Author, string Body, double HoursAgo, string[]? Likers = null, DemoComment[]? Replies = null,
        bool Deleted = false, bool HiddenAsSpam = false, bool Pinned = false);

    private sealed record DemoThread(ArticlePick Article, DemoComment[] Comments);

    private enum ArticlePick
    {
        MostRead,
        SecondMostRead,
        ImagesPost,
        DocumentPost,
    }

    private const string ImagesSlug = "demo-media-angular-workshop";
    private const string DocumentSlug = "demo-media-clean-architecture-pdf";

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
        new(ArticlePick.ImagesPost,
        [
            new("reader2", "Where can I find the Signal Store example from the second photo?", 70, ["reader1", "reader3", "writer2"], Pinned: true,
                Replies:
                [
                    new("writer1", "@reader2 it's in the workshop repo, folder signals/ — I'll add the link to the post.", 69, ["reader2", "reader1"]),
                ]),
            new("reader1", "الصور دي من ورشة امبارح؟ كانت تحفة بجد", 60, ["writer1"],
            [
                new("writer1", "أيوه 😄 هنزل الـ slides قريب.", 58, ["reader1"]),
            ]),
        ]),
        new(ArticlePick.DocumentPost,
        [
            new("reviewer.dotnet", "الـ diagram في صفحة 4 بيلخص الفكرة كلها 👌", 26, ["writer.verified", "reader4"],
            [
                new("writer.verified", "شكرًا! ده كان أصعب جزء أرسمه.", 25, ["reviewer.dotnet"]),
            ]),
        ]),
    ];

    public string Name => "demo-comments";
    public int Order => 11;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of([.. Threads.SelectMany(t => Flatten(t.Comments)).Select(c =>
            $"{c.Author}|{c.Body}|{c.HoursAgo}|{string.Join(',', c.Likers ?? [])}|{c.Deleted}|{c.HiddenAsSpam}|{c.Pinned}")]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var handles = Threads.SelectMany(t => Flatten(t.Comments)).SelectMany(c => (c.Likers ?? []).Append(c.Author)).Append("moderator").Distinct().ToList();
        var emails = handles.Select(h => $"{h}@readin.test").ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => u.Id, cancellationToken);
        if (!users.TryGetValue("moderator", out var moderatorId)) return true;

        var articles = await PickArticlesAsync(cancellationToken);
        var demoUserIds = users.Values.ToList();
        var articleIds = articles.Values.ToList();

        // Replace the demo users' comments on these articles (likes, mentions and their reports go with them).
        var old = await db.Comments.IgnoreQueryFilters()
            .Where(c => articleIds.Contains(c.ArticleId) && c.AuthorId != null && demoUserIds.Contains(c.AuthorId.Value))
            .Select(c => c.Id).ToListAsync(cancellationToken);
        await db.Reports.Where(r => r.TargetType == ReportTargetType.Comment && old.Contains(r.TargetId)).ExecuteDeleteAsync(cancellationToken);
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
        await db.Comments.IgnoreQueryFilters().Where(c => articleIds.Contains(c.ArticleId))
            .ExecuteUpdateAsync(s => s
                .SetProperty(c => c.LikeCount, c => db.CommentLikes.Count(l => l.CommentId == c.Id))
                .SetProperty(c => c.ReplyCount, c => db.Comments.Count(r => r.ParentId == c.Id && !r.IsDeleted && r.HiddenAt == null)),
                cancellationToken);
        await db.Articles.IgnoreQueryFilters().Where(a => articleIds.Contains(a.Id))
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

    private async Task<Dictionary<ArticlePick, Guid>> PickArticlesAsync(CancellationToken ct)
    {
        var published = db.Articles.AsNoTracking().Where(a => a.Status == ArticleStatus.Published);
        var picks = new Dictionary<ArticlePick, Guid>();

        var mostRead = await published
            .Where(a => a.Slug != ImagesSlug && a.Slug != DocumentSlug)
            .OrderByDescending(a => a.ReadCount).ThenBy(a => a.Slug)
            .Select(a => a.Id).Take(2).ToListAsync(ct);
        if (mostRead.Count > 0) picks[ArticlePick.MostRead] = mostRead[0];
        if (mostRead.Count > 1) picks[ArticlePick.SecondMostRead] = mostRead[1];

        var posts = await published.Where(a => a.Slug == ImagesSlug || a.Slug == DocumentSlug)
            .Select(a => new { a.Id, a.Slug }).ToListAsync(ct);
        foreach (var post in posts) picks[post.Slug == ImagesSlug ? ArticlePick.ImagesPost : ArticlePick.DocumentPost] = post.Id;
        return picks;
    }

    private static IReadOnlyCollection<Guid> Mentions(string body, IReadOnlyDictionary<string, Guid> users) =>
        [.. CommentText.MentionedUsernames(body).Select(u => users.TryGetValue(u, out var id) ? id : Guid.Empty).Where(id => id != Guid.Empty)];

    private static IEnumerable<DemoComment> Flatten(IEnumerable<DemoComment> comments) =>
        comments.SelectMany(c => (c.Replies ?? []).Prepend(c));
}
