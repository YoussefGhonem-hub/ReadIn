using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Seo;

/// <summary>
/// GET /sitemap: every public page search engines may index (SPEC §23). The web's server turns it into
/// <c>/sitemap.xml</c> (one file per article language plus one for the other pages) with its own URL shapes.
/// Only what a guest can open: article versions readers can see (<see cref="ArticleVisibility.Visible"/>); writers who
/// aren't suspended, their categories and the tags that are not hidden, each with at least one such article; enabled
/// fields; published learning paths with at least one such article (their page is a 404 otherwise). Cached: a publish,
/// an edit, a hide or a delete clears it with the feed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetSitemapQuery : IQuery<Result<SitemapDto>>, ICachedQuery
{
    /// <summary>Newest first; one sitemap file holds at most 50,000 URLs (sitemaps.org), one file per language.</summary>
    public const int MaxArticles = 40_000;

    public string CacheKey => "sitemap";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Feed, Common.Behaviors.CacheTags.Taxonomy, Common.Behaviors.CacheTags.Tags];
    public TimeSpan Expiration => TimeSpan.FromMinutes(30);
}

/// <summary>The public pages, as data: the web builds the URLs (<c>web/src/server/sitemap.ts</c>).</summary>
public sealed record SitemapDto(
    IReadOnlyList<SitemapArticleDto> Articles,
    IReadOnlyList<SitemapWriterDto> Writers,
    IReadOnlyList<SitemapCategoryDto> Categories,
    IReadOnlyList<SitemapPageDto> Fields,
    IReadOnlyList<SitemapPageDto> Tags,
    IReadOnlyList<SitemapPageDto> Paths);

/// <summary>One language version of an article: <c>/{ar|en}/a/{slug}</c>.</summary>
public sealed record SitemapArticleDto(string Slug, string Language, DateTime LastModified);

/// <summary><c>/@{username}</c>; <see cref="LastModified"/> is their newest article.</summary>
public sealed record SitemapWriterDto(string Username, DateTime LastModified);

/// <summary><c>/@{username}/c/{slug}</c>; <see cref="LastModified"/> is its newest article.</summary>
public sealed record SitemapCategoryDto(string Username, string Slug, DateTime LastModified);

/// <summary>A field (<c>/f/{slug}</c>), tag (<c>/tags/{slug}</c>) or path (<c>/paths/{slug}</c>).</summary>
public sealed record SitemapPageDto(string Slug, DateTime? LastModified);

internal sealed class GetSitemapQueryHandler(IAppDbContext db, TimeProvider clock) : IQueryHandler<GetSitemapQuery, Result<SitemapDto>>
{
    public async ValueTask<Result<SitemapDto>> Handle(GetSitemapQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var visible = db.Articles.AsNoTracking().Visible().Where(a => a.PublishedAt != null);
        // As a profile (ProfileDtos.Shown): a suspended writer's page is a 404 until the suspension ends.
        var writers = db.Users.AsNoTracking().Where(u => !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)));

        var versions = await visible
            .OrderByDescending(a => a.PublishedAt).ThenByDescending(a => a.Id)
            .Take(GetSitemapQuery.MaxArticles)
            .SelectMany(a => a.Translations.Select(t => new
            {
                a.Id,
                PublishedAt = a.PublishedAt!.Value,
                a.Slug,
                t.Language,
                LastModified = a.UpdatedAt ?? a.PublishedAt!.Value,
            }))
            .ToListAsync(ct);
        var articles = versions
            .OrderByDescending(v => v.PublishedAt).ThenByDescending(v => v.Id).ThenBy(v => v.Language, StringComparer.Ordinal)
            .Select(v => new SitemapArticleDto(v.Slug, v.Language, v.LastModified))
            .ToList();

        var writerPages = await visible
            .Where(a => a.AuthorId != null)
            .GroupBy(a => a.AuthorId!.Value)
            .Select(g => new { UserId = g.Key, LastModified = g.Max(a => a.PublishedAt!.Value) })
            .Join(writers, w => w.UserId, u => u.Id, (w, u) => new { u.Username, w.LastModified })
            .OrderBy(w => w.Username)
            .Select(w => new SitemapWriterDto(w.Username, w.LastModified))
            .ToListAsync(ct);

        var categories = await visible
            .Where(a => a.WriterCategoryId != null && a.AuthorId != null)
            .GroupBy(a => a.WriterCategoryId!.Value)
            .Select(g => new { CategoryId = g.Key, LastModified = g.Max(a => a.PublishedAt!.Value) })
            .Join(db.WriterCategories.AsNoTracking(), c => c.CategoryId, c => c.Id, (c, category) => new { category.UserId, category.Slug, category.SortOrder, c.LastModified })
            .Join(writers, c => c.UserId, u => u.Id, (c, u) => new { u.Username, c.Slug, c.SortOrder, c.LastModified })
            .OrderBy(c => c.Username).ThenBy(c => c.SortOrder)
            .Select(c => new SitemapCategoryDto(c.Username, c.Slug, c.LastModified))
            .ToListAsync(ct);

        var fields = await db.Fields.AsNoTracking()
            .Where(f => f.IsEnabled)
            .OrderBy(f => f.Slug)
            .Select(f => new SitemapPageDto(f.Slug, null))
            .ToListAsync(ct);

        var tags = await db.Tags.AsNoTracking()
            .Where(t => !t.IsHidden)
            .Select(t => new { t.Slug, LastModified = visible.Where(a => a.Tags.Any(x => x.TagId == t.Id)).Max(a => a.PublishedAt) })
            .Where(t => t.LastModified != null)
            .OrderBy(t => t.Slug)
            .Select(t => new SitemapPageDto(t.Slug, t.LastModified))
            .ToListAsync(ct);

        var paths = await db.LearningPaths.AsNoTracking()
            .Where(p => p.IsPublished && db.Fields.Any(f => f.Id == p.FieldId && f.IsEnabled))
            .Where(p => p.Items.Any(i => visible.Any(a => a.Id == i.ArticleId)))
            .OrderBy(p => p.SortOrder).ThenBy(p => p.Slug)
            .Select(p => new SitemapPageDto(p.Slug, p.UpdatedAt ?? p.CreatedAt))
            .ToListAsync(ct);

        return new SitemapDto(articles, writerPages, categories, fields, tags, paths);
    }
}
