using System.Globalization;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Search;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Admin.Content;

// The admin console's Content (SPEC F23): every published and archived article, the latest comments, and featuring.

/// <summary>A row of GET /admin/articles, and GET /admin/articles/{id}.</summary>
/// <param name="Status"><c>published</c> or <c>archived</c>.</param>
/// <param name="Title">The caller's UI-language version (<c>ar</c> → <c>ar-EG</c>), else the source.</param>
/// <param name="HiddenAt">Hidden by a moderator (F22); null otherwise.</param>
/// <param name="FeaturedAt">Featured on Explore (F23); null otherwise.</param>
/// <param name="ReportCount">Reports of any status: more than 0 means the F22 case exists.</param>
public sealed record AdminArticleRowDto(
    Guid Id,
    string Slug,
    string Status,
    string Title,
    string Language,
    AuthorDto? Author,
    FieldRefDto Field,
    FieldRefDto? Topic,
    DateTime? PublishedAt,
    int ReadCount,
    int ReactionCount,
    int CommentCount,
    DateTime? HiddenAt,
    DateTime? FeaturedAt,
    int OpenReports,
    int ReportCount);

public sealed record AdminCommentArticleDto(Guid Id, string Slug, string Title, string Language);

/// <summary>A row of GET /admin/comments ("Latest comments").</summary>
/// <param name="ParentId">A reply: its top-level comment.</param>
public sealed record AdminCommentRowDto(
    Guid Id,
    string Body,
    AuthorDto? Author,
    AdminCommentArticleDto Article,
    Guid? ParentId,
    DateTime CreatedAt,
    DateTime? EditedAt,
    DateTime? HiddenAt,
    int LikeCount,
    int ReplyCount,
    int OpenReports,
    int ReportCount);

/// <summary>
/// GET /admin/articles (SPEC F23, <c>moderation.manage</c>): published and archived articles, hidden ones included, never
/// drafts or deleted ones. Every filter is optional; a bad value is <c>400 validation.failed</c> on its parameter.
/// </summary>
/// <param name="From">First-publish date from (<c>YYYY-MM-DD</c> in <c>Admin:TimeZone</c>, included).</param>
/// <param name="To">First-publish date to (included).</param>
/// <param name="Sort"><c>published</c> (default, newest first) or <c>featured</c> (most recently featured first).</param>
[Authenticated]
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetAdminArticlesQuery(
    string? From = null,
    string? To = null,
    string? Field = null,
    string? Topic = null,
    string? Writer = null,
    string? Status = null,
    string? Hidden = null,
    string? Featured = null,
    string? Reported = null,
    string? Q = null,
    string? Sort = null,
    int? Page = null,
    int? PageSize = null) : IQuery<Result<PagedList<AdminArticleRowDto>>>;

/// <summary>GET /admin/articles/{id} ("Open in console"): one row. <c>article.not_found</c> for drafts and deleted articles.</summary>
[Authenticated]
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetAdminArticleQuery(Guid Id) : IQuery<Result<AdminArticleRowDto>>;

/// <summary>
/// GET /admin/comments (SPEC F23, <c>moderation.manage</c>): the newest comments and replies across all articles, so spam
/// shows up before anyone reports it. Deleted comments, and those of deleted articles, are left out; hidden ones are in.
/// </summary>
/// <param name="Hidden"><c>true</c> or <c>false</c>; omitted = both.</param>
[Authenticated]
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record GetAdminCommentsQuery(string? Hidden = null, int? Page = null, int? PageSize = null)
    : IQuery<Result<PagedList<AdminCommentRowDto>>>;

/// <summary>
/// PUT /admin/articles/{id}/featured (SPEC F23, <c>articles.feature</c>): features an article readers can open on Explore.
/// Featuring it again keeps its time. <c>article.not_found</c> for anything readers can't open.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Feature)]
public sealed record FeatureArticleCommand(Guid Id) : ICommand<Result>;

/// <summary>DELETE /admin/articles/{id}/featured: unfeatures any article that isn't deleted, readable or not; idempotent.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Feature)]
public sealed record UnfeatureArticleCommand(Guid Id) : ICommand<Result>;

internal static class AdminContentRows
{
    public const string Published = "published";
    public const string Archived = "archived";
    public const string SortPublished = "published";
    public const string SortFeatured = "featured";

    /// <summary>Published and archived articles (the query filter leaves deleted ones out).</summary>
    public static IQueryable<Article> Listed(IAppDbContext db) =>
        db.Articles.AsNoTracking().Where(a => a.Status == ArticleStatus.Published || a.Status == ArticleStatus.Archived);

    public static IQueryable<AdminArticleRowDto> Rows(IAppDbContext db, IQueryable<Article> articles, string ui)
    {
        var lang = ArticleLanguages.ForUi(ui);
        var english = ui == UiLanguages.English;
        return articles.Select(a => new AdminArticleRowDto(
            a.Id,
            a.Slug,
            a.Status == ArticleStatus.Archived ? Archived : Published,
            a.Translations.Where(t => t.Language == lang).Select(t => t.Title).FirstOrDefault()
                ?? a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault() ?? "",
            a.Translations.Any(t => t.Language == lang) ? lang : a.SourceLanguage,
            a.Author == null
                ? null
                : new AuthorDto(a.Author.Id, a.Author.DisplayName, a.Author.Username, a.Author.AvatarUrl, a.Author.IsVerified, a.Author.Headline),
            new FieldRefDto(a.Field.Id, a.Field.Slug, english ? a.Field.NameEn : a.Field.NameAr, a.Field.NameAr, a.Field.NameEn, a.Field.IsSensitive),
            a.Topic == null
                ? null
                : new FieldRefDto(a.Topic.Id, a.Topic.Slug, english ? a.Topic.NameEn : a.Topic.NameAr, a.Topic.NameAr, a.Topic.NameEn,
                    a.Field.IsSensitive),
            a.PublishedAt,
            a.ReadCount,
            a.ReactionCount,
            a.CommentCount,
            a.HiddenAt,
            a.FeaturedAt,
            db.Reports.Count(r => r.TargetType == ReportTargetType.Article && r.TargetId == a.Id && r.Status == ReportStatus.Open),
            db.Reports.Count(r => r.TargetType == ReportTargetType.Article && r.TargetId == a.Id)));
    }

    /// <summary>Avatar URLs are stored relative; the API sends absolute ones.</summary>
    public static AdminArticleRowDto WithUrls(this AdminArticleRowDto row, IFileStorage storage) =>
        row.Author is null ? row : row with { Author = row.Author with { AvatarUrl = storage.ToPublicUrl(row.Author.AvatarUrl) } };

    public static bool TryParseBool(string? value, out bool? result)
    {
        result = null;
        if (string.IsNullOrWhiteSpace(value)) return true;
        if (bool.TryParse(value.Trim(), out var parsed))
        {
            result = parsed;
            return true;
        }
        return false;
    }

    public static bool TryParseDate(string? value, out DateOnly? result)
    {
        result = null;
        if (string.IsNullOrWhiteSpace(value)) return true;
        if (DateOnly.TryParseExact(value.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
        {
            result = parsed;
            return true;
        }
        return false;
    }

    public static bool TryParseGuid(string? value, out Guid? result)
    {
        result = null;
        if (string.IsNullOrWhiteSpace(value)) return true;
        if (Guid.TryParse(value.Trim(), out var parsed))
        {
            result = parsed;
            return true;
        }
        return false;
    }
}

internal sealed class GetAdminArticlesQueryHandler(IAppDbContext db, ICurrentUser currentUser, AdminClock adminClock, IFileStorage storage)
    : IQueryHandler<GetAdminArticlesQuery, Result<PagedList<AdminArticleRowDto>>>
{
    public const int MaxQueryLength = 100;

    public async ValueTask<Result<PagedList<AdminArticleRowDto>>> Handle(GetAdminArticlesQuery query, CancellationToken ct)
    {
        if (!AdminContentRows.TryParseDate(query.From, out var from)) return AdminErrors.InvalidParameter("from");
        if (!AdminContentRows.TryParseDate(query.To, out var to)) return AdminErrors.InvalidParameter("to");
        if (!AdminContentRows.TryParseGuid(query.Field, out var fieldId)) return AdminErrors.InvalidParameter("field");
        if (!AdminContentRows.TryParseGuid(query.Topic, out var topicId)) return AdminErrors.InvalidParameter("topic");
        if (!AdminContentRows.TryParseGuid(query.Writer, out var writerId)) return AdminErrors.InvalidParameter("writer");
        if (!AdminContentRows.TryParseBool(query.Hidden, out var hidden)) return AdminErrors.InvalidParameter("hidden");
        if (!AdminContentRows.TryParseBool(query.Featured, out var featured)) return AdminErrors.InvalidParameter("featured");
        if (!AdminContentRows.TryParseBool(query.Reported, out var reported)) return AdminErrors.InvalidParameter("reported");
        var status = string.IsNullOrWhiteSpace(query.Status) ? null : query.Status.Trim();
        if (status is not (null or AdminContentRows.Published or AdminContentRows.Archived)) return AdminErrors.InvalidParameter("status");
        var sort = string.IsNullOrWhiteSpace(query.Sort) ? AdminContentRows.SortPublished : query.Sort.Trim();
        if (sort is not (AdminContentRows.SortPublished or AdminContentRows.SortFeatured)) return AdminErrors.InvalidParameter("sort");

        var articles = AdminContentRows.Listed(db);
        var (fromUtc, toUtc) = adminClock.Range(from, to);
        if (fromUtc is { } start) articles = articles.Where(a => a.PublishedAt >= start);
        if (toUtc is { } end) articles = articles.Where(a => a.PublishedAt < end);
        if (fieldId is { } field) articles = articles.Where(a => a.FieldId == field);
        if (topicId is { } topic) articles = articles.Where(a => a.TopicId == topic);
        if (writerId is { } writer) articles = articles.Where(a => a.AuthorId == writer);
        if (status == AdminContentRows.Published) articles = articles.Where(a => a.Status == ArticleStatus.Published);
        if (status == AdminContentRows.Archived) articles = articles.Where(a => a.Status == ArticleStatus.Archived);
        if (hidden is { } isHidden) articles = articles.Where(a => (a.HiddenAt != null) == isHidden);
        if (featured is { } isFeatured) articles = articles.Where(a => (a.FeaturedAt != null) == isFeatured);
        if (reported is { } isReported)
        {
            articles = articles.Where(a => db.Reports.Any(r =>
                r.TargetType == ReportTargetType.Article && r.TargetId == a.Id && r.Status == ReportStatus.Open) == isReported);
        }

        if (!string.IsNullOrWhiteSpace(query.Q))
        {
            if (query.Q.Length > MaxQueryLength) return AdminErrors.InvalidParameter("q");
            var terms = SearchTerms.Parse(query.Q);
            if (terms.IsFailure) return AdminErrors.InvalidParameter("q");
            // Every word in the title of one version (SPEC §22 normalization on both sides).
            foreach (var word in terms.Value.Words)
            {
                var pattern = SearchTerms.ContainsPattern(word);
                articles = articles.Where(a => a.Translations.Any(t =>
                    EF.Functions.Like(ArabicNormalizer.InSql(t.Title), pattern, SearchTerms.LikeEscape)));
            }
        }

        articles = sort == AdminContentRows.SortFeatured
            ? articles.OrderByDescending(a => a.FeaturedAt).ThenByDescending(a => a.PublishedAt).ThenByDescending(a => a.Id)
            : articles.OrderByDescending(a => a.PublishedAt).ThenByDescending(a => a.Id);

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        var rows = await AdminContentRows.Rows(db, articles, currentUser.UiLanguage).ToPagedListAsync(page, pageSize, ct);
        return rows with { Items = [.. rows.Items.Select(r => r.WithUrls(storage))] };
    }
}

internal sealed class GetAdminArticleQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetAdminArticleQuery, Result<AdminArticleRowDto>>
{
    public async ValueTask<Result<AdminArticleRowDto>> Handle(GetAdminArticleQuery query, CancellationToken ct)
    {
        var row = await AdminContentRows.Rows(db, AdminContentRows.Listed(db).Where(a => a.Id == query.Id), currentUser.UiLanguage)
            .FirstOrDefaultAsync(ct);
        return row is null ? ArticleErrors.NotFound : row.WithUrls(storage);
    }
}

internal sealed class GetAdminCommentsQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetAdminCommentsQuery, Result<PagedList<AdminCommentRowDto>>>
{
    public async ValueTask<Result<PagedList<AdminCommentRowDto>>> Handle(GetAdminCommentsQuery query, CancellationToken ct)
    {
        if (!AdminContentRows.TryParseBool(query.Hidden, out var hidden)) return AdminErrors.InvalidParameter("hidden");

        var lang = ArticleLanguages.ForUi(currentUser.UiLanguage);
        // The query filters leave deleted comments and deleted articles out.
        var comments = db.Comments.AsNoTracking().Join(db.Articles, c => c.ArticleId, a => a.Id, (c, a) => new { Comment = c, Article = a });
        if (hidden is { } isHidden) comments = comments.Where(x => (x.Comment.HiddenAt != null) == isHidden);

        var rows = comments
            .OrderByDescending(x => x.Comment.CreatedAt).ThenByDescending(x => x.Comment.Id)
            .Select(x => new AdminCommentRowDto(
                x.Comment.Id,
                x.Comment.Body,
                x.Comment.Author == null
                    ? null
                    : new AuthorDto(x.Comment.Author.Id, x.Comment.Author.DisplayName, x.Comment.Author.Username, x.Comment.Author.AvatarUrl,
                        x.Comment.Author.IsVerified, x.Comment.Author.Headline),
                new AdminCommentArticleDto(
                    x.Article.Id,
                    x.Article.Slug,
                    x.Article.Translations.Where(t => t.Language == lang).Select(t => t.Title).FirstOrDefault()
                        ?? x.Article.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault() ?? "",
                    x.Article.Translations.Any(t => t.Language == lang) ? lang : x.Article.SourceLanguage),
                x.Comment.ParentId,
                x.Comment.CreatedAt,
                x.Comment.EditedAt,
                x.Comment.HiddenAt,
                x.Comment.LikeCount,
                x.Comment.ReplyCount,
                db.Reports.Count(r => r.TargetType == ReportTargetType.Comment && r.TargetId == x.Comment.Id && r.Status == ReportStatus.Open),
                db.Reports.Count(r => r.TargetType == ReportTargetType.Comment && r.TargetId == x.Comment.Id)));

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        var paged = await rows.ToPagedListAsync(page, pageSize, ct);
        return paged with
        {
            Items = [.. paged.Items.Select(r => r.Author is null ? r : r with { Author = r.Author with { AvatarUrl = storage.ToPublicUrl(r.Author.AvatarUrl) } })],
        };
    }
}

internal sealed class FeatureArticleCommandHandler(IAppDbContext db, ICurrentUser currentUser, AuditTrail audit, HybridCache cache, TimeProvider clock)
    : ICommandHandler<FeatureArticleCommand, Result>
{
    public async ValueTask<Result> Handle(FeatureArticleCommand command, CancellationToken ct)
    {
        var article = await db.Articles.Where(a => a.Id == command.Id).Visible().FirstOrDefaultAsync(ct);
        if (article is null) return ArticleErrors.NotFound;
        if (!article.Feature(currentUser.RequireUserId(), clock.GetUtcNow().UtcDateTime)) return Result.Success();

        audit.Record(AuditActions.ArticleFeatured, article.AuthorId, AuditTargets.Article, article.Id, article.Slug);
        await db.SaveChangesAsync(ct);
        await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug), CacheTags.ArticleById(article.Id)], ct);
        return Result.Success();
    }
}

internal sealed class UnfeatureArticleCommandHandler(IAppDbContext db, AuditTrail audit, HybridCache cache)
    : ICommandHandler<UnfeatureArticleCommand, Result>
{
    public async ValueTask<Result> Handle(UnfeatureArticleCommand command, CancellationToken ct)
    {
        var article = await db.Articles.FirstOrDefaultAsync(a => a.Id == command.Id, ct);
        if (article is null) return ArticleErrors.NotFound;
        if (!article.Unfeature()) return Result.Success();

        audit.Record(AuditActions.ArticleUnfeatured, article.AuthorId, AuditTargets.Article, article.Id, article.Slug);
        await db.SaveChangesAsync(ct);
        await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug), CacheTags.ArticleById(article.Id)], ct);
        return Result.Success();
    }
}
