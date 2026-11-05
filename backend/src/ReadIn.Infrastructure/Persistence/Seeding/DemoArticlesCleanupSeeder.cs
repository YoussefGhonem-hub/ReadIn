using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Moderation;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Development only (SPEC §18.1: every seeded article is @readin's and comes from <c>content/articles</c>; demo accounts
/// have no articles). Local databases made before that rule still hold the articles of the removed demo seeders
/// (<c>demo-writers</c>, <c>demo-media</c>, <c>demo-editor</c>). This deletes exactly those: each one is matched by its seed
/// slug <em>and</em> the demo author that seeder gave it, so an article of @readin or of anyone else is never touched.
/// <list type="bullet">
/// <item>With what depends on them: translations, drafts, revisions, tags, sources, attachments, reactions, saves,
/// collection items, comments (likes, mentions), reads, daily picks and path items go with the row (cascades); the reports
/// and notifications about them or their comments are deleted first (no cascade); the images and the PDF the demo posts
/// showed go after them (rows, pages and files), unless another article shows them too. The moderation log keeps its
/// entries, as for any deleted article.</item>
/// <item>The categories of the removed <c>demo-categories</c> seeder go too, but only those left empty: one that holds any
/// other article stays.</item>
/// <item>Then the removed "Verified Writer" demo account itself (+12025550106, <c>writer.verified@readin.test</c>, both must
/// match), through the app's account deletion (<see cref="IAccountEraser"/>, as <c>DELETE /me</c> and the identity cleanup
/// job do), so everything that depends on it goes by the data map of SPEC §9.6.</item>
/// <item>Idempotent: the checksum is what is still there to delete, so it runs again only when there is something to do.
/// The articles part writes no outbox events.</item>
/// </list>
/// </summary>
internal sealed partial class DemoArticlesCleanupSeeder(
    AppDbContext db,
    IFileStorage storage,
    IAccountEraser eraser,
    IUserAccessService access,
    ILogger<DemoArticlesCleanupSeeder> logger)
    : ISeeder
{
    /// <summary>The removed "Verified Writer" demo account (SPEC §18.3 no longer lists it).</summary>
    internal const string RemovedAccountPhone = "+12025550106";

    internal const string RemovedAccountEmail = "writer.verified@readin.test";

    /// <param name="Handle">The demo user (e-mail <c>{Handle}@readin.test</c>) the old seeder made it for.</param>
    internal sealed record OldArticle(string Slug, string Handle);

    internal sealed record OldCategory(string Handle, string Name);

    /// <summary>Every article the removed demo seeders created, with its author.</summary>
    internal static readonly OldArticle[] OldArticles =
    [
        // demo-writers
        new("demo-writers-covering-indexes", "writer2"),
        new("demo-writers-asnotracking", "writer2"),
        new("demo-writers-execution-plans", "writer3"),
        new("demo-writers-endpoint-groups", "reviewer.dotnet"),
        new("demo-writers-rag-retrieval-first", "reviewer.ai"),
        new("demo-writers-prompt-examples", "reviewer.ai"),
        // demo-media
        new("demo-media-angular-workshop", "writer1"),
        new("demo-media-clean-architecture-pdf", "writer.verified"),
        // demo-editor
        new("demo-editor-angular-signals-draft", "writer1"),
        new("demo-editor-riverpod-draft", "writer.verified"),
        new("flutter-feature-first-folders", "writer.verified"),
    ];

    /// <summary>Every category the removed demo-categories seeder created.</summary>
    internal static readonly OldCategory[] OldCategories =
    [
        new("writer1", "ورش Angular"),
        new("writer1", "TypeScript"),
        new("writer.verified", "Cheat sheets"),
        new("writer2", "قواعد البيانات"),
        new("reviewer.ai", "RAG"),
        new("reviewer.ai", "Prompt engineering"),
    ];

    public string Name => "demo-articles-cleanup";
    public int Order => 9; // after the articles, before the demo interactions, reads and comments re-run on @readin's articles
    public int Version => 2; // 2: the removed "Verified Writer" account goes too

    public bool AppliesTo(IHostEnvironment environment) => environment.IsDevelopment();

    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var articles = await FindArticlesAsync(cancellationToken);
        var categories = await FindCategoriesAsync(articles, cancellationToken);
        string[] account = await FindRemovedAccountAsync(cancellationToken) is { } id ? [$"account:{id}"] : [];
        return SeedChecksum.Of([
            $"v{Version}", .. articles.Select(a => a.ToString()), .. categories.Select(c => c.ToString()), .. account]);
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var articleIds = await FindArticlesAsync(cancellationToken);
        var categoryIds = await FindCategoriesAsync(articleIds, cancellationToken);
        if (articleIds.Count > 0 || categoryIds.Count > 0) await DeleteArticlesAsync(articleIds, categoryIds, cancellationToken);

        // After its articles, so they are deleted like the other old demo articles instead of kept without an author.
        if (await FindRemovedAccountAsync(cancellationToken) is { } account)
        {
            await eraser.EraseAsync(account, cancellationToken);
            await access.InvalidateAsync(account, cancellationToken);
            LogAccountRemoved(logger, account);
        }
        return true;
    }

    private async Task DeleteArticlesAsync(List<Guid> articleIds, List<Guid> categoryIds, CancellationToken cancellationToken)
    {
        List<string> files = [];
        var (articles, categories) = (0, 0);
        var strategy = db.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async ct =>
        {
            db.ChangeTracker.Clear(); // a retried attempt starts from a clean slate
            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // The images and PDF the posts show, unless another article shows them too.
            var assets = await db.MediaAssets.AsNoTracking().Include(m => m.Pages)
                .Where(m => db.ArticleAttachments.Any(x => x.MediaAssetId == m.Id && articleIds.Contains(x.ArticleId))
                            && !db.ArticleAttachments.Any(x => x.MediaAssetId == m.Id && !articleIds.Contains(x.ArticleId)))
                .ToListAsync(ct);

            // Reports and notifications about the articles or the comments on them (their keys don't cascade).
            await db.Reports
                .Where(r => (r.TargetType == ReportTargetType.Article && articleIds.Contains(r.TargetId))
                            || (r.TargetType == ReportTargetType.Comment
                                && db.Comments.IgnoreQueryFilters().Any(c => c.Id == r.TargetId && articleIds.Contains(c.ArticleId))))
                .ExecuteDeleteAsync(ct);
            await db.Notifications
                .Where(n => (n.ArticleId != null && articleIds.Contains(n.ArticleId.Value))
                            || (n.CommentId != null
                                && db.Comments.IgnoreQueryFilters().Any(c => c.Id == n.CommentId && articleIds.Contains(c.ArticleId))))
                .ExecuteDeleteAsync(ct);

            articles = await db.Articles.IgnoreQueryFilters().Where(a => articleIds.Contains(a.Id)).ExecuteDeleteAsync(ct);
            var assetIds = assets.Select(m => m.Id).ToList();
            await db.MediaAssets.Where(m => assetIds.Contains(m.Id)).ExecuteDeleteAsync(ct);
            categories = await db.WriterCategories
                .Where(c => categoryIds.Contains(c.Id) && !db.Articles.IgnoreQueryFilters().Any(a => a.WriterCategoryId == c.Id))
                .ExecuteDeleteAsync(ct);

            await transaction.CommitAsync(ct);
            files = [.. assets.SelectMany(m => m.StoredPaths())];
        }, cancellationToken);

        foreach (var file in files)
        {
            try
            {
                await storage.DeleteAsync(file, cancellationToken);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
            {
                LogFileNotDeleted(logger, ex, file); // an orphan now: the daily uploads cleanup removes it
            }
        }

        LogCleaned(logger, articles, categories, files.Count);
    }

    /// <summary>The removed "Verified Writer" account, if this database still has it (a soft-deleted one too).</summary>
    private async Task<Guid?> FindRemovedAccountAsync(CancellationToken ct) =>
        await db.Users.IgnoreQueryFilters().AsNoTracking()
            .Where(u => u.PhoneNumber == RemovedAccountPhone && u.Email == RemovedAccountEmail)
            .Select(u => (Guid?)u.Id)
            .FirstOrDefaultAsync(ct);

    /// <summary>The old demo articles still there (soft-deleted ones too), each by its slug and its demo author.</summary>
    private async Task<List<Guid>> FindArticlesAsync(CancellationToken ct)
    {
        var slugs = OldArticles.Select(a => a.Slug).ToList();
        var found = await db.Articles.IgnoreQueryFilters().AsNoTracking()
            .Where(a => slugs.Contains(a.Slug) && a.AuthorId != null)
            .Select(a => new { a.Id, a.Slug, a.Author!.Email })
            .ToListAsync(ct);
        return [.. found
            .Where(a => OldArticles.Any(o => o.Slug == a.Slug && string.Equals(Email(o.Handle), a.Email, StringComparison.OrdinalIgnoreCase)))
            .Select(a => a.Id)
            .Order()];
    }

    /// <summary>The old demo categories that hold nothing once the old demo articles are gone.</summary>
    private async Task<List<Guid>> FindCategoriesAsync(List<Guid> oldArticles, CancellationToken ct)
    {
        var emails = OldCategories.Select(c => Email(c.Handle)).Distinct().ToList();
        var owners = await db.Users.IgnoreQueryFilters().AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .Select(u => new { u.Id, u.Email })
            .ToListAsync(ct);
        var wanted = OldCategories
            .SelectMany(c => owners.Where(o => string.Equals(o.Email, Email(c.Handle), StringComparison.OrdinalIgnoreCase))
                .Select(o => (o.Id, Key: WriterCategoryNames.Normalize(WriterCategoryNames.Clean(c.Name)))))
            .ToHashSet();
        if (wanted.Count == 0) return [];

        var ownerIds = owners.Select(o => o.Id).ToList();
        var candidates = await db.WriterCategories.AsNoTracking()
            .Where(c => ownerIds.Contains(c.UserId)
                        && !db.Articles.IgnoreQueryFilters().Any(a => a.WriterCategoryId == c.Id && !oldArticles.Contains(a.Id)))
            .Select(c => new { c.Id, c.UserId, c.NormalizedName })
            .ToListAsync(ct);
        return [.. candidates.Where(c => wanted.Contains((c.UserId, c.NormalizedName))).Select(c => c.Id).Order()];
    }

    private static string Email(string handle) => $"{handle}@readin.test";

    [LoggerMessage(Level = LogLevel.Information,
        Message = "Removed the old demo data: {Articles} demo articles, {Categories} empty demo categories, {Files} media files")]
    private static partial void LogCleaned(ILogger logger, int articles, int categories, int files);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete {Path} of an old demo article; the orphaned uploads job will")]
    private static partial void LogFileNotDeleted(ILogger logger, Exception exception, string path);

    [LoggerMessage(Level = LogLevel.Information, Message = "Deleted the removed \"Verified Writer\" demo account {UserId}")]
    private static partial void LogAccountRemoved(ILogger logger, Guid userId);
}
