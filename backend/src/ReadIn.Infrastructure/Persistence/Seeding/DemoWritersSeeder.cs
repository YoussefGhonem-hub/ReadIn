using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Content;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Development only (demo data, SPEC §18.2): short articles by demo writers who otherwise publish nothing (writer2,
/// writer3 and the two reviewers, never a system account), so Explore (F15) has new writers, top writers on the field
/// pages and topic chips with articles. It runs before the demo interactions, which then save and react to these
/// articles too. The checksum includes today's date, so it re-runs once a day and moves each article's first publish
/// back to its planned number of days ago: "New writers" (first article in the last 30 days) never goes empty.
/// Idempotent by slug; the published articles raise no events (no notifications for demo data).
/// </summary>
internal sealed class DemoWritersSeeder(AppDbContext db, IRDocProcessor rdoc, TimeProvider clock) : ISeeder
{
    /// <param name="DaysAgo">The article's first publish, in days before today.</param>
    internal sealed record Plan(string Slug, string Handle, string Field, string? Topic, string Language, string Title, string Text, int DaysAgo);

    internal static readonly Plan[] Plans =
    [
        new("demo-writers-covering-indexes", "writer2", "databases", "indexing", ArticleLanguages.English,
            "Covering indexes in five minutes",
            "A covering index holds every column a query needs, so SQL Server never goes back to the table. Add the extra columns with INCLUDE and watch the key lookups disappear from the plan.",
            2),
        new("demo-writers-asnotracking", "writer2", "dotnet", "ef-core", ArticleLanguages.EgyptianArabic,
            "إمتى تستخدم AsNoTracking في EF Core؟",
            "لو انت بتقرا بس ومش هتعدل، AsNoTracking بيوفر عليك الـ change tracker كله. في الـ API اللي بترجع lists ده فرق واضح في الـ memory والسرعة.",
            12),
        new("demo-writers-execution-plans", "writer3", "databases", "query-tuning", ArticleLanguages.EgyptianArabic,
            "اقرا الـ execution plan من غير ما تتوه",
            "ابدأ من اليمين لليسار، ودوّر على أتقل operator. الـ Key Lookup والـ Scan على جدول كبير غالبًا هم أول حاجة تتصلح، وبعدها راجع الـ estimated rows.",
            5),
        new("demo-writers-endpoint-groups", "reviewer.dotnet", "dotnet", "minimal-apis", ArticleLanguages.English,
            "Minimal APIs: group your endpoints",
            "MapGroup gives a set of endpoints one prefix, one tag and one authorization policy. Keep one group per feature and the Program file stays short.",
            1),
        new("demo-writers-rag-retrieval-first", "reviewer.ai", "ai-fundamentals", "rag", ArticleLanguages.English,
            "RAG is retrieval first",
            "Most bad RAG answers are retrieval problems, not model problems. Measure whether the right chunk is in the top five before you touch the prompt.",
            8),
        new("demo-writers-prompt-examples", "reviewer.ai", "ai-fundamentals", "prompt-engineering", ArticleLanguages.EgyptianArabic,
            "الـ prompt الكويس بيبدأ بمثال",
            "بدل ما توصف الشكل اللي عايزه في فقرة طويلة، اديله مثال واحد واضح للـ input والـ output. الموديل بيقلد المثال أسرع ما بيفهم الوصف.",
            20),
    ];

    public string Name => "demo-writers";
    public int Order => 9;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => environment.IsDevelopment();

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var today = ReadingClock.LocalDate(clock.GetUtcNow().UtcDateTime, User.DefaultTimeZone);
        return Task.FromResult(SeedChecksum.Of(
            [$"v{Version}", today.ToString("yyyy-MM-dd"), .. Plans.Select(p => $"{p.Slug}|{p.Handle}|{p.Field}|{p.Topic}|{p.Title}|{p.DaysAgo}")]));
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var emails = Plans.Select(p => $"{p.Handle}@readin.test").Distinct().ToList();
        var writers = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email) && !u.IsSystemAccount)
            .ToDictionaryAsync(u => u.Email!.Split('@')[0], u => u.Id, cancellationToken);
        var fields = await db.Fields.Include(f => f.Topics).Where(f => f.IsEnabled).OrderBy(f => f.SortOrder).ToListAsync(cancellationToken);
        if (fields.Count == 0) return true;

        foreach (var plan in Plans)
        {
            if (!writers.TryGetValue(plan.Handle, out var authorId)) continue;
            var publishedAt = now.AddDays(-plan.DaysAgo);

            if (await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Slug == plan.Slug, cancellationToken))
            {
                // Already there: keep its first publish the planned number of days ago (published, not deleted only).
                await db.Articles
                    .Where(a => a.Slug == plan.Slug && a.Status == ArticleStatus.Published)
                    .ExecuteUpdateAsync(s => s.SetProperty(a => a.PublishedAt, publishedAt), cancellationToken);
                continue;
            }

            var field = fields.FirstOrDefault(f => f.Slug == plan.Field) ?? fields[0];
            var topicId = field.Topics.FirstOrDefault(t => t.Slug == plan.Topic)?.Id;
            var document = JsonSerializer.SerializeToElement(new
            {
                version = 1,
                language = plan.Language,
                blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text = plan.Text } } } },
            });
            var content = rdoc.Process(document, plan.Language, plan.Title);
            if (content.IsFailure) throw new InvalidOperationException($"Demo article '{plan.Slug}' is invalid: {content.Error.Code}");

            var article = Article.CreateDraft(authorId, field.Id, topicId, plan.Slug, sourceLanguage: plan.Language);
            article.AddTranslation(plan.Language, plan.Title, null, content.Value.Content);
            article.SetSources([("ReadIn demo", "https://readin.app")]);
            db.Articles.Add(article);
            await db.SaveChangesAsync(cancellationToken);

            if (article.Publish(field, publishedAt).IsFailure) continue;
            article.ClearDomainEvents(); // demo data: no "new article" notifications to the writer's followers
            await db.SaveChangesAsync(cancellationToken);
        }
        return true;
    }
}
