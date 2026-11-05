using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Development only (SPEC F22, §18.2): a moderation queue that isn't empty locally. Demo readers report two of @readin's
/// articles, a comment and reader7 (who posts the demo spam comment); one resolved case (reader7 was warned for spam, so
/// reader7 also has a warning notice to acknowledge) and one dismissed case (a disagreement, not a broken rule). Runs after
/// the demo comments and writes no outbox events, so nothing is pushed. The demo SuperAdmin moderates (there is no demo
/// moderator any more). A re-run replaces the demo reports and the demo moderation actions on these targets.
/// </summary>
internal sealed class DemoReportsSeeder(AppDbContext db, TimeProvider clock) : ISeeder
{
    private enum Pick
    {
        ThirdMostRead,
        FourthMostRead,
        Reader4Comment,
        Writer3Comment,
        Reader7,
    }

    private sealed record DemoReport(Pick Target, string Reporter, ReportReason Reason, string? Details, double HoursAgo,
        ReportStatus Status = ReportStatus.Open);

    private const string WarningNote = "روابط الإعلانات في التعليقات ممنوعة. لو اتكررت هيتوقف الحساب.";
    private const string DismissNote = "خلاف في الرأي، مش مخالفة للقواعد.";
    private const double WarnedHoursAgo = 48;
    private const double DismissedHoursAgo = 24;

    private static readonly DemoReport[] Reports =
    [
        new(Pick.ThirdMostRead, "reader3", ReportReason.Misinformation, "الأرقام في الجدول التاني قديمة ومش متحدثة.", 30),
        new(Pick.ThirdMostRead, "reader5", ReportReason.Misinformation, null, 20),
        new(Pick.ThirdMostRead, "reader8", ReportReason.Other, "The second code sample doesn't compile.", 6),
        new(Pick.FourthMostRead, "reader4", ReportReason.Copyright, "أول فقرة منقولة من مدونة تانية من غير ما يذكر المصدر.", 12),
        new(Pick.Reader4Comment, "reader9", ReportReason.Spam, "Looks like a bot comment.", 2),
        new(Pick.Reader7, "reader1", ReportReason.Spam, "بينزل لينكات لقناته في التعليقات.", 5),
        new(Pick.Reader7, "reader2", ReportReason.Spam, null, 4),
        // Resolved by the warning below.
        new(Pick.Reader7, "reader3", ReportReason.Spam, "Spam links under every article.", 60, ReportStatus.Resolved),
        // Dismissed.
        new(Pick.Writer3Comment, "reader10", ReportReason.Other, "مش موافق على الكلام ده.", 30, ReportStatus.Dismissed),
    ];

    public string Name => "demo-reports";
    public int Order => 12;
    public int Version => 2; // 2: the SuperAdmin moderates

    public bool AppliesTo(IHostEnvironment environment) => environment.IsDevelopment();

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [WarningNote, DismissNote, .. Reports.Select(r => $"{r.Target}|{r.Reporter}|{r.Reason}|{r.Details}|{r.HoursAgo}|{r.Status}")]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var handles = Reports.Select(r => r.Reporter).Concat(["reader4", "reader7", "writer3"]).Distinct().ToList();
        var emails = handles.Select(h => $"{h}@readin.test").ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => (u.Id, u.Username), cancellationToken);
        var moderator = await db.Users.AsNoTracking().Where(u => u.Id == SystemUsers.SuperAdminId).Select(u => new { u.Id }).FirstOrDefaultAsync(cancellationToken);
        if (moderator is null) return true;

        var targets = await PickTargetsAsync(users, cancellationToken);
        var targetIds = targets.Values.Select(t => t.Id).ToList();
        var reporterIds = Reports.Select(r => users.GetValueOrDefault(r.Reporter).Id).Where(id => id != Guid.Empty).ToList();
        await db.Reports.Where(r => targetIds.Contains(r.TargetId) && reporterIds.Contains(r.ReporterId)).ExecuteDeleteAsync(cancellationToken);
        // The demo actions by their notes, whoever made them (an older local database has them by the demo moderator).
        await db.ModerationActions.Where(m => targetIds.Contains(m.TargetId) && (m.Note == WarningNote || m.Note == DismissNote))
            .ExecuteDeleteAsync(cancellationToken);

        var reports = new List<(Report Report, DemoReport Demo)>();
        foreach (var demo in Reports)
        {
            if (!targets.TryGetValue(demo.Target, out var target) || !users.TryGetValue(demo.Reporter, out var reporter)) continue;
            var report = Report.File(target.Type, target.Id, reporter.Id, demo.Reason, demo.Details, now.AddHours(-demo.HoursAgo));
            if (demo.Status == ReportStatus.Resolved) report.Resolve(moderator.Id, now.AddHours(-WarnedHoursAgo));
            if (demo.Status == ReportStatus.Dismissed) report.Dismiss(moderator.Id, now.AddHours(-DismissedHoursAgo));
            db.Reports.Add(report);
            reports.Add((report, demo));
        }

        if (targets.TryGetValue(Pick.Reader7, out var spammer) && users.TryGetValue("reader7", out var reader7))
        {
            var resolved = reports.Count(r => r.Demo.Target == Pick.Reader7 && r.Demo.Status == ReportStatus.Resolved);
            db.ModerationActions.Add(ModerationAction.Warning(spammer.Id, reader7.Username, moderator.Id, WarningNote, resolved,
                now.AddHours(-WarnedHoursAgo)));
        }
        if (targets.TryGetValue(Pick.Writer3Comment, out var disagreement))
        {
            var dismissed = reports.Count(r => r.Demo.Target == Pick.Writer3Comment && r.Demo.Status == ReportStatus.Dismissed);
            var comment = await db.Comments.AsNoTracking().Where(c => c.Id == disagreement.Id).Select(c => new { c.AuthorId, c.Body })
                .FirstAsync(cancellationToken);
            if (dismissed > 0)
            {
                db.ModerationActions.Add(ModerationAction.Dismissal(ReportTargetType.Comment, disagreement.Id, comment.AuthorId, comment.Body,
                    moderator.Id, DismissNote, dismissed, now.AddHours(-DismissedHoursAgo)));
            }
        }

        // Demo data never goes through the outbox: no notice push.
        foreach (var entry in db.ChangeTracker.Entries<AggregateRoot>()) entry.Entity.ClearDomainEvents();
        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<Dictionary<Pick, (ReportTargetType Type, Guid Id)>> PickTargetsAsync(
        IReadOnlyDictionary<string, (Guid Id, string Username)> users, CancellationToken ct)
    {
        var picks = new Dictionary<Pick, (ReportTargetType, Guid)>();

        // Two of @readin's articles (the only seeded ones, SPEC §18.1): the third and fourth most read.
        var articles = await db.Articles.AsNoTracking()
            .Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status == ArticleStatus.Published && a.HiddenAt == null)
            .OrderByDescending(a => a.ReadCount).ThenBy(a => a.Slug)
            .Select(a => a.Id).Skip(2).Take(2).ToListAsync(ct);
        if (articles.Count > 0) picks[Pick.ThirdMostRead] = (ReportTargetType.Article, articles[0]);
        if (articles.Count > 1) picks[Pick.FourthMostRead] = (ReportTargetType.Article, articles[1]);

        foreach (var (pick, handle) in new[] { (Pick.Reader4Comment, "reader4"), (Pick.Writer3Comment, "writer3") })
        {
            if (!users.TryGetValue(handle, out var author)) continue;
            var commentId = await db.Comments.AsNoTracking()
                .Where(c => c.AuthorId == author.Id && c.ParentId == null && c.HiddenAt == null)
                .OrderBy(c => c.CreatedAt)
                .Select(c => (Guid?)c.Id)
                .FirstOrDefaultAsync(ct);
            if (commentId is { } id) picks[pick] = (ReportTargetType.Comment, id);
        }

        if (users.TryGetValue("reader7", out var reader7)) picks[Pick.Reader7] = (ReportTargetType.User, reader7.Id);
        return picks;
    }
}
