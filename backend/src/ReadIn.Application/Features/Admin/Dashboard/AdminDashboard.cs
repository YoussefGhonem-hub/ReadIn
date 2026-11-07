using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Admin.Dashboard;

// ---- DTOs (contract-v1 "Admin console (F23)") ----

/// <summary>GET /admin/summary: the badge on the console entry. Each count is null without its permission.</summary>
public sealed record AdminSummaryDto(int? OpenReports, int? OpenTickets, int? PendingVerifications, int Total);

public sealed record DashboardValueDto(int Value, int Previous);

/// <summary>New users in the period, split by how they signed up (<c>Users.SignUpMethod</c>).</summary>
public sealed record DashboardNewUsersDto(int Value, int Previous, int Phone, int Google, int Apple);

public sealed record DashboardCardsDto(
    DashboardValueDto ArticlesPublished,
    DashboardNewUsersDto NewUsers,
    DashboardValueDto ActiveReaders,
    DashboardValueDto Reads,
    DashboardValueDto Comments,
    DashboardValueDto Reactions,
    DashboardValueDto Reposts,
    int? OpenReports,
    int? OpenTickets,
    int? PendingVerifications,
    int SuspendedNow);

public sealed record DashboardDayDto(string Date, int NewUsers, int ActiveReaders, int ArticlesPublished);

public sealed record DashboardArticleDto(
    Guid Id, string Slug, string Title, string Language, AuthorDto? Author, FieldRefDto Field, DateTime PublishedAt, int Reads);

public sealed record DashboardWriterDto(AuthorDto Writer, int Reads, int Articles);

public sealed record DashboardMissedSearchDto(string Query, string Language, int Count);

public sealed record StreakRetentionDto(int Cohort, int Kept, double? Rate);

public sealed record ContentPipelineDto(int Folders, int Seeded, int Published, DateTime? LastSeedRunAt);

public sealed record AdminDashboardDto(
    string Period,
    string TimeZone,
    DateTime From,
    DateTime To,
    string FromDate,
    string ToDate,
    DateTime GeneratedAt,
    DashboardCardsDto Cards,
    IReadOnlyList<DashboardDayDto> Charts,
    IReadOnlyList<DashboardArticleDto> TopArticles,
    IReadOnlyList<DashboardWriterDto> TopWriters,
    IReadOnlyList<DashboardMissedSearchDto> MissedSearches,
    StreakRetentionDto StreakRetention,
    ContentPipelineDto ContentPipeline);

/// <summary>
/// What the database doesn't hold about the content pipeline (SPEC §19, F23): the article folders shipped in
/// <c>content/articles</c> and the last seed run. Implemented in Infrastructure.
/// </summary>
public interface IContentPipelineSource
{
    /// <summary>Folders with a <c>meta.json</c> under <c>content/articles</c>; read once per process.</summary>
    int ArticleFolders();

    /// <summary>The newest <c>SeedHistory.AppliedAt</c>; null before the first seed run.</summary>
    Task<DateTime?> LastSeedRunAsync(CancellationToken cancellationToken);
}

/// <summary>
/// Open support tickets for the badge and the dashboard (SPEC F35). F35 isn't built yet: zero until it replaces this.
/// </summary>
public interface IOpenTicketCounter
{
    Task<int> CountOpenAsync(CancellationToken cancellationToken);
}

internal sealed class NoOpenTickets : IOpenTicketCounter
{
    public Task<int> CountOpenAsync(CancellationToken cancellationToken) => Task.FromResult(0);
}

// ---- Queries ----

/// <summary>GET /admin/summary (SPEC F23): open reports + open tickets + pending verification requests. Not cached.</summary>
[RequirePermission(Permissions.Admin.Access)]
public sealed record GetAdminSummaryQuery : IQuery<Result<AdminSummaryDto>>;

/// <summary>GET /admin/dashboard?period= (SPEC F23). The period's numbers are cached 60 s per period and UI language.</summary>
[RequirePermission(Permissions.Admin.Access)]
public sealed record GetAdminDashboardQuery(string? Period, string UiLanguage) : IQuery<Result<AdminDashboardDto>>;

/// <summary>The counts every holder of their permission sees right now (the state cards and the badge).</summary>
internal sealed class AdminQueueCounts(IAppDbContext db, ICurrentUser currentUser, IOpenTicketCounter tickets, AdminClock clock)
{
    public async Task<int?> OpenReportsAsync(CancellationToken ct) =>
        currentUser.Permissions.Contains(Permissions.Moderation.Manage)
            ? await db.Reports.AsNoTracking()
                .Where(r => r.Status == ReportStatus.Open)
                .Select(r => new { r.TargetType, r.TargetId })
                .Distinct()
                .CountAsync(ct)
            : null;

    public async Task<int?> OpenTicketsAsync(CancellationToken ct) =>
        currentUser.Permissions.Contains(Permissions.Support.Manage) ? await tickets.CountOpenAsync(ct) : null;

    public async Task<int?> PendingVerificationsAsync(CancellationToken ct) =>
        currentUser.Permissions.Contains(Permissions.Verification.Manage)
            ? await db.VerificationRequests.AsNoTracking().CountAsync(r => r.Status == VerificationStatus.Pending, ct)
            : null;

    public async Task<int> SuspendedNowAsync(CancellationToken ct)
    {
        var now = clock.UtcNow;
        return await db.Users.AsNoTracking()
            .CountAsync(u => u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now), ct);
    }
}

internal sealed class GetAdminSummaryQueryHandler(AdminQueueCounts counts) : IQueryHandler<GetAdminSummaryQuery, Result<AdminSummaryDto>>
{
    public async ValueTask<Result<AdminSummaryDto>> Handle(GetAdminSummaryQuery query, CancellationToken cancellationToken)
    {
        var reports = await counts.OpenReportsAsync(cancellationToken);
        var tickets = await counts.OpenTicketsAsync(cancellationToken);
        var verifications = await counts.PendingVerificationsAsync(cancellationToken);
        return new AdminSummaryDto(reports, tickets, verifications, (reports ?? 0) + (tickets ?? 0) + (verifications ?? 0));
    }
}

internal sealed class GetAdminDashboardQueryHandler(AdminDashboardReader reader, AdminQueueCounts counts, HybridCache cache)
    : IQueryHandler<GetAdminDashboardQuery, Result<AdminDashboardDto>>
{
    public const string CacheTag = "admin-dashboard";

    private static readonly HybridCacheEntryOptions Ttl = new()
    {
        Expiration = TimeSpan.FromSeconds(60),
        LocalCacheExpiration = TimeSpan.FromSeconds(60),
    };

    public async ValueTask<Result<AdminDashboardDto>> Handle(GetAdminDashboardQuery query, CancellationToken cancellationToken)
    {
        var period = string.IsNullOrWhiteSpace(query.Period) ? AdminPeriods.Today : query.Period.Trim().ToLowerInvariant();
        if (!AdminPeriods.IsKnown(period)) return AdminErrors.InvalidParameter("period");

        var ui = UiLanguages.Normalize(query.UiLanguage);
        var dashboard = await cache.GetOrCreateAsync(
            $"admin:dashboard:{period}:{ui}",
            (Reader: reader, Period: period, Ui: ui),
            static async (state, ct) => await state.Reader.ReadAsync(state.Period, state.Ui, ct),
            Ttl,
            [CacheTag],
            cancellationToken);

        // The state cards are what each caller may see, right now.
        var cards = dashboard.Cards with
        {
            OpenReports = await counts.OpenReportsAsync(cancellationToken),
            OpenTickets = await counts.OpenTicketsAsync(cancellationToken),
            PendingVerifications = await counts.PendingVerificationsAsync(cancellationToken),
            SuspendedNow = await counts.SuspendedNowAsync(cancellationToken),
        };
        return dashboard with { Cards = cards };
    }
}

/// <summary>
/// The dashboard's numbers (SPEC F23, contract decisions 4–6): SQL counts for the cards, small projections bucketed into
/// local days for the charts. No personal data: articles and writers as on public pages, searches without who searched.
/// </summary>
internal sealed class AdminDashboardReader(IAppDbContext db, AdminClock clock, IContentPipelineSource content)
{
    private const int ChartDays = 30;
    private const int TopArticles = 10;
    private const int TopWriters = 10;
    private const int TopMissedSearches = 20;
    private const int StreakKeptFrom = 3;

    public async Task<AdminDashboardDto> ReadAsync(string period, string ui, CancellationToken ct)
    {
        var window = clock.Window(period);
        var cards = new DashboardCardsDto(
            await ValueAsync(ArticlesPublishedAsync, window, ct),
            await NewUsersAsync(window, ct),
            await ValueAsync(ActiveReadersAsync, window, ct),
            await ValueAsync(ReadsAsync, window, ct),
            await ValueAsync(CommentsAsync, window, ct),
            await ValueAsync(ReactionsAsync, window, ct),
            await ValueAsync(RepostsAsync, window, ct),
            OpenReports: null, OpenTickets: null, PendingVerifications: null, SuspendedNow: 0);

        return new AdminDashboardDto(
            period,
            clock.TimeZoneId,
            window.FromUtc,
            window.ToUtc,
            Iso(window.FromDate),
            Iso(window.ToDate),
            clock.UtcNow,
            cards,
            await ChartsAsync(ct),
            await TopArticlesAsync(window, ui, ct),
            await TopWritersAsync(window, ct),
            await MissedSearchesAsync(window, ct),
            await StreakRetentionAsync(ct),
            await ContentPipelineAsync(ct));
    }

    private static string Iso(DateOnly date) => date.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);

    private static async Task<DashboardValueDto> ValueAsync(
        Func<DateTime, DateTime, CancellationToken, Task<int>> count, AdminWindow window, CancellationToken ct) =>
        new(await count(window.FromUtc, window.ToUtc, ct), await count(window.PreviousFromUtc, window.PreviousToUtc, ct));

    private Task<int> ArticlesPublishedAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.Articles.AsNoTracking().CountAsync(a => a.PublishedAt >= from && a.PublishedAt < to, ct);

    private Task<int> ActiveReadersAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.ReadingProgress.AsNoTracking()
            .Where(r => r.CompletedAt >= from && r.CompletedAt < to)
            .Select(r => r.UserId)
            .Distinct()
            .CountAsync(ct);

    private Task<int> ReadsAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.ReadingProgress.AsNoTracking().CountAsync(r => r.CompletedAt >= from && r.CompletedAt < to, ct);

    private Task<int> CommentsAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.Comments.AsNoTracking().CountAsync(c => c.CreatedAt >= from && c.CreatedAt < to, ct);

    private Task<int> ReactionsAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.Reactions.AsNoTracking().CountAsync(r => r.ReactedAt >= from && r.ReactedAt < to, ct);

    private Task<int> RepostsAsync(DateTime from, DateTime to, CancellationToken ct) =>
        db.Reposts.AsNoTracking().CountAsync(r => r.CreatedAt >= from && r.CreatedAt < to, ct);

    private async Task<DashboardNewUsersDto> NewUsersAsync(AdminWindow window, CancellationToken ct)
    {
        var methods = await db.Users.AsNoTracking()
            .Where(u => !u.IsSystemAccount && u.CreatedAt >= window.FromUtc && u.CreatedAt < window.ToUtc)
            .GroupBy(u => u.SignUpMethod)
            .Select(g => new { Method = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var previous = await db.Users.AsNoTracking()
            .CountAsync(u => !u.IsSystemAccount && u.CreatedAt >= window.PreviousFromUtc && u.CreatedAt < window.PreviousToUtc, ct);

        int Of(string method) => methods.Where(m => m.Method == method).Sum(m => m.Count);
        var google = Of(SignUpMethods.Google);
        var apple = Of(SignUpMethods.Apple);
        var total = methods.Sum(m => m.Count);
        return new DashboardNewUsersDto(total, previous, total - google - apple, google, apple);
    }

    /// <summary>The last 30 local days up to today, oldest first, zeros included, whatever the period.</summary>
    private async Task<IReadOnlyList<DashboardDayDto>> ChartsAsync(CancellationToken ct)
    {
        var today = clock.Today;
        var first = today.AddDays(-(ChartDays - 1));
        var from = clock.StartOfDayUtc(first);
        var to = clock.UtcNow;

        var joined = await db.Users.AsNoTracking()
            .Where(u => !u.IsSystemAccount && u.CreatedAt >= from && u.CreatedAt < to)
            .Select(u => u.CreatedAt)
            .ToListAsync(ct);
        var reads = await db.ReadingProgress.AsNoTracking()
            .Where(r => r.CompletedAt >= from && r.CompletedAt < to)
            .Select(r => new { r.UserId, CompletedAt = r.CompletedAt!.Value })
            .ToListAsync(ct);
        var published = await db.Articles.AsNoTracking()
            .Where(a => a.PublishedAt >= from && a.PublishedAt < to)
            .Select(a => a.PublishedAt!.Value)
            .ToListAsync(ct);

        var newUsers = joined.GroupBy(clock.LocalDate).ToDictionary(g => g.Key, g => g.Count());
        var readers = reads.GroupBy(r => clock.LocalDate(r.CompletedAt)).ToDictionary(g => g.Key, g => g.Select(r => r.UserId).Distinct().Count());
        var articles = published.GroupBy(clock.LocalDate).ToDictionary(g => g.Key, g => g.Count());

        return [.. Enumerable.Range(0, ChartDays)
            .Select(first.AddDays)
            .Select(day => new DashboardDayDto(
                Iso(day), newUsers.GetValueOrDefault(day), readers.GetValueOrDefault(day), articles.GetValueOrDefault(day)))];
    }

    private async Task<IReadOnlyList<DashboardArticleDto>> TopArticlesAsync(AdminWindow window, string ui, CancellationToken ct)
    {
        var language = ArticleLanguages.ForUi(ui);
        var reads = db.ReadingProgress.AsNoTracking()
            .Where(r => r.CompletedAt >= window.FromUtc && r.CompletedAt < window.ToUtc)
            .GroupBy(r => r.ArticleId)
            .Select(g => new { ArticleId = g.Key, Reads = g.Count() });

        var top = await db.Articles.AsNoTracking().Visible()
            .Join(reads, a => a.Id, r => r.ArticleId, (a, r) => new { Article = a, r.Reads })
            .OrderByDescending(x => x.Reads)
            .ThenByDescending(x => x.Article.PublishedAt)
            .ThenByDescending(x => x.Article.Id)
            .Take(TopArticles)
            .Select(x => new
            {
                x.Article.Id,
                x.Article.Slug,
                x.Reads,
                PublishedAt = x.Article.PublishedAt!.Value,
                Version = x.Article.Translations
                    .OrderBy(t => t.Language == language ? 0 : t.Language == x.Article.SourceLanguage ? 1 : 2)
                    .Select(t => new { t.Language, t.Title })
                    .FirstOrDefault(),
                Author = x.Article.Author == null
                    ? null
                    : new AuthorDto(x.Article.Author.Id, x.Article.Author.DisplayName, x.Article.Author.Username,
                        x.Article.Author.AvatarUrl, x.Article.Author.IsVerified, x.Article.Author.Headline),
                Field = new FieldRefDto(x.Article.Field.Id, x.Article.Field.Slug,
                    ui == UiLanguages.English ? x.Article.Field.NameEn : x.Article.Field.NameAr,
                    x.Article.Field.NameAr, x.Article.Field.NameEn, x.Article.Field.IsSensitive),
            })
            .ToListAsync(ct);

        return [.. top.Select(a => new DashboardArticleDto(
            a.Id, a.Slug, a.Version?.Title ?? a.Slug, a.Version?.Language ?? language, a.Author, a.Field, a.PublishedAt, a.Reads))];
    }

    private async Task<IReadOnlyList<DashboardWriterDto>> TopWritersAsync(AdminWindow window, CancellationToken ct)
    {
        var top = await db.ReadingProgress.AsNoTracking()
            .Where(r => r.CompletedAt >= window.FromUtc && r.CompletedAt < window.ToUtc)
            .Join(db.Articles.Where(a => a.AuthorId != null), r => r.ArticleId, a => a.Id, (r, a) => new { AuthorId = a.AuthorId!.Value, r.ArticleId })
            .GroupBy(x => x.AuthorId)
            .Select(g => new { AuthorId = g.Key, Reads = g.Count(), Articles = g.Select(x => x.ArticleId).Distinct().Count() })
            .OrderByDescending(x => x.Reads)
            .ThenByDescending(x => x.Articles)
            .ThenBy(x => x.AuthorId)
            .Take(TopWriters)
            .ToListAsync(ct);
        if (top.Count == 0) return [];

        var ids = top.Select(x => x.AuthorId).ToList();
        var writers = await db.Users.AsNoTracking()
            .Where(u => ids.Contains(u.Id))
            .Select(u => new AuthorDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline))
            .ToDictionaryAsync(u => u.Id, ct);
        return [.. top
            .Where(x => writers.ContainsKey(x.AuthorId))
            .Select(x => new DashboardWriterDto(writers[x.AuthorId], x.Reads, x.Articles))];
    }

    private async Task<IReadOnlyList<DashboardMissedSearchDto>> MissedSearchesAsync(AdminWindow window, CancellationToken ct)
    {
        var from = window.FromDate;
        var to = window.ToDate;
        var misses = await db.SearchMisses.AsNoTracking()
            .Where(m => m.Date >= from && m.Date <= to)
            .GroupBy(m => new { m.Query, m.Language })
            .Select(g => new { g.Key.Query, g.Key.Language, Count = g.Sum(m => m.Count) })
            .OrderByDescending(m => m.Count)
            .ThenBy(m => m.Query)
            .Take(TopMissedSearches)
            .ToListAsync(ct);
        return [.. misses.Select(m => new DashboardMissedSearchDto(m.Query, m.Language, m.Count))];
    }

    /// <summary>
    /// Last week's active readers (a read in the 7 days before today) and those of them whose reading streak is 3 or more and
    /// still alive (they read yesterday or today). Doesn't depend on the period.
    /// </summary>
    private async Task<StreakRetentionDto> StreakRetentionAsync(CancellationToken ct)
    {
        var today = clock.Today;
        var from = clock.StartOfDayUtc(today.AddDays(-7));
        var to = clock.StartOfDayUtc(today);
        var yesterday = today.AddDays(-1);

        var cohort = db.ReadingProgress.AsNoTracking()
            .Where(r => r.CompletedAt >= from && r.CompletedAt < to)
            .Select(r => r.UserId)
            .Distinct();
        var size = await cohort.CountAsync(ct);
        var kept = await db.UserStats.AsNoTracking()
            .Where(s => cohort.Contains(s.UserId) && s.CurrentStreak >= StreakKeptFrom && s.LastReadDate >= yesterday)
            .CountAsync(ct);
        return new StreakRetentionDto(size, kept, size == 0 ? null : Math.Round(kept / (double)size, 3));
    }

    private async Task<ContentPipelineDto> ContentPipelineAsync(CancellationToken ct)
    {
        var official = db.Articles.AsNoTracking().Where(a => a.Author != null && a.Author.IsSystemAccount);
        return new ContentPipelineDto(
            content.ArticleFolders(),
            await official.CountAsync(ct),
            await official.Visible().CountAsync(ct),
            await content.LastSeedRunAsync(ct));
    }
}
