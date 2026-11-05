using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Development only (SPEC F17, §18.2): a notification center that isn't empty locally. reader1 (the main demo reader) gets
/// a reply and a mention from the demo comments, a new article from writer1, today's article, a streak reminder and a
/// security alert; writer1 gets the comments on their images post and a reactions milestone and three new followers in one
/// aggregated entry; reader2 a mention; reader7 the warning of the demo reports. Some are read, most aren't. Rows only: no
/// outbox events and no pushes (every entry has no push). Runs after the demo comments and reports; a re-run replaces its
/// own entries (their dedupe keys start with <c>demo:</c>), and it runs again whenever the demo comments were replaced.
/// </summary>
internal sealed class DemoNotificationsSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    private const string KeyPrefix = "demo:";
    private const string ImagesSlug = "demo-media-angular-workshop";
    private static readonly string[] Handles = ["reader1", "reader2", "reader3", "reader5", "reader7", "writer1"];

    public string Name => "demo-notifications";
    public int Order => 13;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => environment.IsDevelopment();

    /// <summary>The comments and notice it points at: new ids (the demo comments were seeded again) mean a re-run.</summary>
    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var targets = await LoadTargetsAsync(cancellationToken);
        return SeedChecksum.Of(
        [
            $"v{Version}",
            .. targets.Users.OrderBy(u => u.Key).Select(u => $"{u.Key}={u.Value}"),
            $"{targets.ImagesPost}|{targets.Reader1Comment}|{targets.Writer1Reply}|{targets.Reader2Comment}|{targets.Writer1Mention}",
            $"{targets.Reader3Mention}|{targets.MostRead}|{targets.Warning}",
        ]);
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var t = await LoadTargetsAsync(cancellationToken);
        await db.Notifications.Where(n => n.DedupeKey != null && n.DedupeKey.StartsWith(KeyPrefix)).ExecuteDeleteAsync(cancellationToken);

        var now = clock.GetUtcNow().UtcDateTime;
        DateTime Ago(double hours) => now.AddHours(-hours);
        Guid? User(string handle) => t.Users.TryGetValue(handle, out var id) ? id : null;

        // writer1: the comments on the images post, a milestone, and today's new followers.
        if (User("writer1") is { } writer1 && t.ImagesPost is { } imagesPost)
        {
            if (User("reader2") is { } reader2 && User("reader1") is { } reader1 && t.Reader1Comment is { } reader1Comment)
            {
                var comments = Entry(writer1, NotificationTypes.ArticleComment, "writer1-comments", Ago(70), reader2,
                    group: $"{NotificationTypes.ArticleComment}:{imagesPost}", article: imagesPost, comment: t.Reader2Comment);
                comments.AddActivity(reader1, Ago(60), reader1Comment, repeatsCount: true, Ago(60), pushAfter: null);
            }
            Entry(writer1, NotificationTypes.ReactionsMilestone, "writer1-milestone", Ago(30), actor: null, article: imagesPost,
                data: new NotificationData { Threshold = 10 }, readAt: Ago(29));
        }
        if (User("writer1") is { } followee)
        {
            var followers = new[] { "reader1", "reader3", "reader5" }.Select(User).OfType<Guid>().ToList();
            if (followers.Count > 0)
            {
                var day = Ago(5);
                var entry = Entry(followee, NotificationTypes.NewFollower, "writer1-followers", day, followers[0],
                    group: $"{NotificationTypes.NewFollower}:{DateOnly.FromDateTime(day):yyyy-MM-dd}");
                for (var i = 1; i < followers.Count; i++)
                    entry.AddActivity(followers[i], Ago(5 - i), null, repeatsCount: false, Ago(5 - i), pushAfter: null);
            }
        }

        // reader1: a reply, a mention, a new article, today's article, a streak reminder and a security alert.
        if (User("reader1") is { } me)
        {
            if (User("writer1") is { } writer && t.Writer1Reply is { } reply && t.Reader1Comment is { } parent)
            {
                Entry(me, NotificationTypes.CommentReply, "reader1-reply", Ago(58), writer, group: $"{NotificationTypes.CommentReply}:{parent}",
                    article: t.ImagesPost, comment: reply);
            }
            if (User("reader3") is { } reader3 && t.Reader3Mention is { } mention)
                Entry(me, NotificationTypes.Mention, "reader1-mention", Ago(46), reader3, article: t.MostRead, comment: mention);
            if (User("writer1") is { } author && t.ImagesPost is { } post)
                Entry(me, NotificationTypes.FollowedWriterArticle, "reader1-new-article", Ago(72), author, article: post, readAt: Ago(71));
            if (t.MostRead is { } daily)
                Entry(me, NotificationTypes.DailyArticle, "reader1-daily", Ago(3), actor: null, article: daily, readAt: Ago(2));
            Entry(me, NotificationTypes.StreakReminder, "reader1-streak", Ago(20), actor: null, data: new NotificationData { StreakDays = 4 },
                readAt: Ago(19));
            Entry(me, NotificationTypes.SecurityAlert, "reader1-security", Ago(80), actor: null,
                data: new NotificationData { SecurityChange = SecurityChange.PasswordChanged }, readAt: Ago(79));
        }

        // reader2: writer1's answer mentions them.
        if (User("reader2") is { } reader2Id && User("writer1") is { } answering && t.Writer1Mention is { } answer)
            Entry(reader2Id, NotificationTypes.Mention, "reader2-mention", Ago(69), answering, article: t.ImagesPost, comment: answer);

        // reader7: the warning of the demo reports (F22).
        if (User("reader7") is { } reader7 && t.Warning is { } warning)
        {
            Entry(reader7, NotificationTypes.ModerationNotice, "reader7-warning", Ago(48), actor: null,
                data: new NotificationData { NoticeId = warning, NoticeKind = NoticeKinds.Warning });
        }

        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>One entry without a push, created <paramref name="at"/>; read at <paramref name="readAt"/> when given.</summary>
    private Notification Entry(
        Guid userId, string type, string key, DateTime at, Guid? actor, string? group = null, Guid? article = null, Guid? comment = null,
        NotificationData? data = null, DateTime? readAt = null)
    {
        var entry = Notification.Create(userId, type, at, pushAfter: null, group, KeyPrefix + key, article, comment,
            (data ?? NotificationData.Empty).Serialize(), actor, at);
        if (readAt is { } read) entry.MarkRead(read);
        db.Notifications.Add(entry);
        return entry;
    }

    private sealed record Targets(
        Dictionary<string, Guid> Users,
        Guid? ImagesPost,
        Guid? MostRead, // the article of reader3's mention (the demo comments' most-read one)
        Guid? Reader1Comment,
        Guid? Writer1Reply,
        Guid? Reader2Comment,
        Guid? Writer1Mention,
        Guid? Reader3Mention,
        Guid? Warning);

    private async Task<Targets> LoadTargetsAsync(CancellationToken ct)
    {
        var emails = Handles.Select(h => $"{h}@readin.test").ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => u.Id, ct);

        var imagesPost = await db.Articles.AsNoTracking()
            .Where(a => a.Status == ArticleStatus.Published && a.Slug == ImagesSlug)
            .Select(a => (Guid?)a.Id).FirstOrDefaultAsync(ct);

        Task<Guid?> Top(string handle, Guid? articleId) => users.TryGetValue(handle, out var author) && articleId is { } article
            ? db.Comments.AsNoTracking().Where(c => c.ArticleId == article && c.AuthorId == author && c.ParentId == null)
                .OrderBy(c => c.CreatedAt).Select(c => (Guid?)c.Id).FirstOrDefaultAsync(ct)
            : Task.FromResult<Guid?>(null);
        Task<Guid?> ReplyTo(string handle, Guid? parentId) => users.TryGetValue(handle, out var author) && parentId is { } parent
            ? db.Comments.AsNoTracking().Where(c => c.ParentId == parent && c.AuthorId == author)
                .OrderBy(c => c.CreatedAt).Select(c => (Guid?)c.Id).FirstOrDefaultAsync(ct)
            : Task.FromResult<Guid?>(null);

        var reader1Comment = await Top("reader1", imagesPost);
        var writer1Reply = await ReplyTo("writer1", reader1Comment);
        var reader2Comment = await Top("reader2", imagesPost);
        var writer1Mention = await ReplyTo("writer1", reader2Comment);
        // reader3's answer that mentions reader1, on the demo comments' most-read article.
        var reader3Mention = users.TryGetValue("reader3", out var reader3) && users.TryGetValue("reader1", out var reader1)
            ? await db.Comments.AsNoTracking()
                .Where(c => c.AuthorId == reader3 && c.HiddenAt == null && c.Mentions.Any(m => m.UserId == reader1))
                .OrderBy(c => c.CreatedAt)
                .Select(c => new { c.Id, c.ArticleId })
                .FirstOrDefaultAsync(ct)
            : null;
        var warning = users.TryGetValue("reader7", out var warned)
            ? await db.ModerationActions.AsNoTracking()
                .Where(m => m.TargetUserId == warned && m.NoticeKind == NoticeKinds.Warning)
                .OrderBy(m => m.CreatedAt).Select(m => (Guid?)m.Id).FirstOrDefaultAsync(ct)
            : null;

        return new Targets(users, imagesPost, reader3Mention?.ArticleId, reader1Comment, writer1Reply, reader2Comment, writer1Mention,
            reader3Mention?.Id, warning);
    }
}
