using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Explore;

/// <summary>
/// GET /fields/{slug}: the field page's header and topic chips (SPEC F15). <c>field.not_found</c> for an unknown or
/// disabled field. The counts are cached for everyone; the caller's follows are added after the cache
/// (<see cref="FieldPagePersonalizer"/>).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFieldPageQuery(string Slug, string UiLanguage) : IQuery<Result<FieldPageDto>>, ICachedQuery
{
    public string CacheKey => $"field-page:{FieldSlugs.FromRoute(Slug)}:{UiLanguages.Normalize(UiLanguage)}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Taxonomy, Common.Behaviors.CacheTags.Feed];
    public TimeSpan Expiration => ExploreLimits.CacheExpiration;
}

/// <summary>
/// GET /fields/{slug}/articles?topic=: the field's articles (or one topic's), newest first, as feed cards (SPEC F15,
/// F34), keyset-paginated over (PublishedAt DESC, Id DESC). Guests get a cached page (server rendering); a signed-in
/// caller's page leaves out the writers and other topics they muted and what they marked "show less" (F28).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFieldArticlesQuery(string Slug, string? Topic, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;

/// <summary>
/// GET /fields/{slug}/writers: "Top writers in this field" (SPEC F15), best first. The ranking is cached for everyone;
/// the caller's follow state is added after the cache (<see cref="FieldWritersPersonalizer"/>).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFieldWritersQuery(string Slug, int Limit) : IQuery<Result<IReadOnlyList<UserSummaryDto>>>, ICachedQuery
{
    public int Size => Math.Clamp(Limit, 1, ExploreLimits.MaxTopWriters);
    public string CacheKey => $"field-writers:{FieldSlugs.FromRoute(Slug)}:{Size}";
    public IReadOnlyCollection<string> CacheTags => [Common.Behaviors.CacheTags.Taxonomy, Common.Behaviors.CacheTags.Feed];
    public TimeSpan Expiration => ExploreLimits.CacheExpiration;
}

internal static class FieldSlugs
{
    /// <summary>Field and topic slugs are lower case; a route or query value is trimmed and lower-cased before the lookup.</summary>
    public static string FromRoute(string? slug) => (slug ?? string.Empty).Trim().ToLowerInvariant();

    /// <summary>The id of the enabled field with <paramref name="slug"/>, or null.</summary>
    public static Task<Guid?> EnabledFieldIdAsync(this IAppDbContext db, string? slug, CancellationToken ct)
    {
        var key = FromRoute(slug);
        return db.Fields.AsNoTracking().Where(f => f.Slug == key && f.IsEnabled).Select(f => (Guid?)f.Id).FirstOrDefaultAsync(ct);
    }
}

internal sealed class GetFieldPageQueryHandler(IAppDbContext db, ExploreRankings rankings)
    : IQueryHandler<GetFieldPageQuery, Result<FieldPageDto>>
{
    public async ValueTask<Result<FieldPageDto>> Handle(GetFieldPageQuery query, CancellationToken ct)
    {
        var slug = FieldSlugs.FromRoute(query.Slug);
        var english = UiLanguages.Normalize(query.UiLanguage) == UiLanguages.English;
        var visible = rankings.Visible();

        var field = await db.Fields.AsNoTracking()
            .Where(f => f.Slug == slug && f.IsEnabled)
            .Select(f => new
            {
                f.Id,
                f.Slug,
                f.NameAr,
                f.NameEn,
                f.Icon,
                f.Color,
                f.IsSensitive,
                Articles = visible.Count(a => a.FieldId == f.Id),
                // People who follow the field itself; a followed topic doesn't count.
                Followers = db.Users.Count(u => u.Interests.Any(i => i.FieldId == f.Id)),
            })
            .FirstOrDefaultAsync(ct);
        if (field is null) return TaxonomyErrors.FieldNotFound;

        var topics = await db.Topics.AsNoTracking()
            .Where(t => t.FieldId == field.Id && t.IsEnabled) // a disabled topic has no chip (F23)
            .OrderBy(t => t.SortOrder).ThenBy(t => t.Slug)
            .Select(t => new FieldPageTopicDto(
                t.Id, t.Slug, english ? t.NameEn : t.NameAr, t.NameAr, t.NameEn, visible.Count(a => a.TopicId == t.Id), false))
            .ToListAsync(ct);

        return new FieldPageDto(
            field.Id, field.Slug, english ? field.NameEn : field.NameAr, field.NameAr, field.NameEn, field.Icon, field.Color,
            field.IsSensitive, field.Articles, field.Followers, IsFollowing: false, topics);
    }
}

/// <summary>Adds the signed-in caller's follows (the field and each topic, F12 interests) to the cached header.</summary>
internal sealed class FieldPagePersonalizer(IAppDbContext db, ICurrentUser viewer) : IQueryPersonalizer<GetFieldPageQuery, Result<FieldPageDto>>
{
    public async ValueTask<Result<FieldPageDto>> PersonalizeAsync(GetFieldPageQuery message, Result<FieldPageDto> response, CancellationToken ct)
    {
        if (response.IsFailure || viewer.UserId is not { } viewerId) return response;

        var page = response.Value;
        var topicIds = page.Topics.Select(t => t.Id).ToList();
        var interests = await db.Users.AsNoTracking()
            .Where(u => u.Id == viewerId)
            .SelectMany(u => u.Interests)
            .Where(i => i.FieldId == page.Id || (i.TopicId != null && topicIds.Contains(i.TopicId.Value)))
            .Select(i => new { i.FieldId, i.TopicId })
            .ToListAsync(ct);
        var followedTopics = interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToHashSet();

        return page with
        {
            IsFollowing = interests.Any(i => i.FieldId == page.Id),
            Topics = [.. page.Topics.Select(t => t with { IsFollowing = followedTopics.Contains(t.Id) })],
        };
    }
}

internal sealed class GetFieldArticlesQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    PathCards paths,
    ExploreRankings rankings,
    HybridCache cache)
    : IQueryHandler<GetFieldArticlesQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetFieldArticlesQuery query, CancellationToken ct)
    {
        if (await db.EnabledFieldIdAsync(query.Slug, ct) is not { } fieldId) return TaxonomyErrors.FieldNotFound;

        Guid? topicId = null;
        if (!string.IsNullOrWhiteSpace(query.Topic))
        {
            var topicSlug = FieldSlugs.FromRoute(query.Topic);
            topicId = await db.Topics.AsNoTracking()
                .Where(t => t.FieldId == fieldId && t.Slug == topicSlug && t.IsEnabled)
                .Select(t => (Guid?)t.Id)
                .FirstOrDefaultAsync(ct);
            if (topicId is null) return TaxonomyErrors.TopicNotFound;
        }

        var limit = Math.Clamp(query.Limit, 1, ExploreLimits.MaxLimit);
        var cursor = TimeCursor.Decode(query.Cursor);
        var ui = UiLanguages.Normalize(query.UiLanguage);
        CursorPage<ArticleCardDto> page;
        if (currentUser.UserId is { } viewerId)
        {
            var articleLanguage = await paths.ArticleLanguageOfAsync(viewerId, ui, ct);
            page = await LoadAsync(fieldId, topicId, cursor, limit, ui, articleLanguage, viewerId, ct);
        }
        else
        {
            // The same for every guest (and the web's server rendering): cached, and refreshed by publish, Update,
            // hide/unhide and delete (CacheTags.Feed).
            var articleLanguage = ArticleLanguages.ForUi(ui);
            page = await cache.GetOrCreateAsync(
                $"field-articles:{fieldId:N}:{topicId?.ToString("N") ?? "-"}:{cursor?.Encode() ?? "-"}:{limit}:{ui}:{articleLanguage}",
                (Handler: this, Field: fieldId, Topic: topicId, Cursor: cursor, Limit: limit, Ui: ui, Lang: articleLanguage),
                static async (state, token) => await state.Handler.LoadAsync(
                    state.Field, state.Topic, state.Cursor, state.Limit, state.Ui, state.Lang, viewerId: null, token),
                ExploreRankings.CacheOptions,
                [CacheTags.Feed, CacheTags.Taxonomy],
                ct);
        }

        return new CursorPage<ArticleCardDto>(await cards.CompleteAsync(page.Items, ct), page.NextCursor);
    }

    /// <summary>One page of cards as SQL projects them, before the viewer's own state is added.</summary>
    private async Task<CursorPage<ArticleCardDto>> LoadAsync(
        Guid fieldId, Guid? topicId, TimeCursor? cursor, int limit, string ui, string? articleLanguage, Guid? viewerId, CancellationToken ct)
    {
        var articles = rankings.Visible().Where(a => a.FieldId == fieldId)
            // The page's own field and the topic picked stay, though muted: the reader opened them (F28).
            .WithoutMutedFor(db, viewerId, openedFieldId: fieldId, openedTopicId: topicId)
            .WithoutShownLessFor(db, viewerId);
        if (topicId is { } topic) articles = articles.Where(a => a.TopicId == topic);
        if (cursor is { } after)
        {
            articles = articles.Where(a =>
                a.PublishedAt < after.Timestamp ||
                (a.PublishedAt == after.Timestamp && a.Id.CompareTo(after.Id) < 0));
        }

        List<ArticleCardDto> items;
        using (LocalizedProjection.Begin(ui, articleLanguage))
        {
            items = await articles
                .OrderByDescending(a => a.PublishedAt)
                .ThenByDescending(a => a.Id)
                .Take(limit + 1)
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
        }

        string? next = null;
        if (items.Count > limit)
        {
            items.RemoveAt(limit);
            var last = items[^1];
            next = new TimeCursor(last.PublishedAt!.Value, last.Id).Encode();
        }
        return new CursorPage<ArticleCardDto>(items, next);
    }
}

internal sealed class GetFieldWritersQueryHandler(IAppDbContext db, ExploreRankings rankings)
    : IQueryHandler<GetFieldWritersQuery, Result<IReadOnlyList<UserSummaryDto>>>
{
    public async ValueTask<Result<IReadOnlyList<UserSummaryDto>>> Handle(GetFieldWritersQuery query, CancellationToken ct)
    {
        if (await db.EnabledFieldIdAsync(query.Slug, ct) is not { } fieldId) return TaxonomyErrors.FieldNotFound;

        var ids = await rankings.TopWriterIdsAsync(fieldId, rankings.Now, query.Size, ct);
        return await rankings.UsersAsync(ids, ct);
    }
}

/// <summary>
/// Leaves out of the cached top writers anyone suspended (or deleted) since, and adds absolute avatar URLs and the
/// caller's follow state.
/// </summary>
internal sealed class FieldWritersPersonalizer(ICurrentUser viewer, ExploreRankings rankings)
    : IQueryPersonalizer<GetFieldWritersQuery, Result<IReadOnlyList<UserSummaryDto>>>
{
    public async ValueTask<Result<IReadOnlyList<UserSummaryDto>>> PersonalizeAsync(
        GetFieldWritersQuery message, Result<IReadOnlyList<UserSummaryDto>> response, CancellationToken ct)
    {
        if (response.IsFailure) return response;
        return await rankings.ForViewerAsync(response.Value, viewer.UserId, ct);
    }
}
