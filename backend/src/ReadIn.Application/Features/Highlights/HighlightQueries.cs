using System.Globalization;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Highlights;

/// <summary>
/// GET /articles/{id}/highlights?lang= (SPEC F30): your highlights on the version and its popular ranges. The block
/// texts and the popular ranges come from the shared cache; yours and your mutes are read per request. Guests allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticleHighlightsQuery(Guid ArticleId, string? Language) : IQuery<Result<ArticleHighlightsDto>>;

/// <summary>
/// GET /me/highlights (SPEC F30, F14 Saved → Highlights): one group per article version, newest highlight first,
/// keyset-paginated over (newest highlight DESC, article id DESC, language DESC). The newest highlight is the group's
/// <c>latestAt</c>, so the order is the one the response shows.
/// </summary>
[Authenticated]
public sealed record GetMyHighlightsQuery(string? Cursor, int Limit) : IQuery<Result<CursorPage<HighlightGroupDto>>>;

internal sealed class GetArticleHighlightsQueryHandler(IAppDbContext db, ICurrentUser viewer, HighlightTexts texts, BlockRelations blocks)
    : IQueryHandler<GetArticleHighlightsQuery, Result<ArticleHighlightsDto>>
{
    public async ValueTask<Result<ArticleHighlightsDto>> Handle(GetArticleHighlightsQuery query, CancellationToken ct)
    {
        var version = await texts.GetVersionAsync(query.ArticleId, query.Language, ct);
        if (version is null || (version.IsHidden && !ArticleVisibility.CanSeeHidden(version.AuthorId, viewer))) return ArticleErrors.NotFound;
        if (await blocks.DirectLinkErrorAsync(viewer, version.AuthorId, ArticleErrors.NotFound, ct) is { } blocked) return blocked;

        var popular = await texts.GetPopularAsync(version, ct);
        List<HighlightDto> mine = [];

        if (viewer.UserId is { } viewerId)
        {
            var own = await db.ArticleHighlights.AsNoTracking()
                .Where(h => h.UserId == viewerId && h.ArticleId == version.ArticleId && h.Language == version.Language)
                .Select(h => new HighlightDto(h.Id, h.BlockId, h.StartOffset, h.EndOffset, h.Text, h.CreatedAt))
                .ToListAsync(ct);
            mine = [.. own
                .Where(h => version.StillMatches(h.BlockId, h.StartOffset, h.EndOffset, h.Text))
                .OrderBy(h => version.OrderKey(h.BlockId, h.StartOffset, h.EndOffset))];

            if (popular.Count > 0) popular = await WithoutMutedAsync(version, viewerId, popular, ct);
        }

        return new ArticleHighlightsDto(
            version.ArticleId,
            version.Language,
            mine,
            [.. popular
                .Where(p => p.Count >= HighlightTexts.PopularThreshold)
                .OrderByDescending(p => p.Count)
                .ThenBy(p => version.OrderKey(p.BlockId, p.StartOffset, p.EndOffset))
                .Take(HighlightTexts.PopularShown)]);
    }

    /// <summary>The writers the viewer muted don't count (SPEC F28, F30): their marks come off each range's count.</summary>
    private async Task<IReadOnlyList<PopularHighlightDto>> WithoutMutedAsync(
        HighlightVersion version, Guid viewerId, IReadOnlyList<PopularHighlightDto> popular, CancellationToken ct)
    {
        var muted = await db.ArticleHighlights.AsNoTracking()
            .Where(h => h.ArticleId == version.ArticleId && h.Language == version.Language
                && db.UserMutes.Any(m => m.MuterId == viewerId && m.MutedUserId == h.UserId))
            .GroupBy(h => new { h.BlockId, h.StartOffset, h.EndOffset, h.Text })
            .Select(g => new { g.Key.BlockId, g.Key.StartOffset, g.Key.EndOffset, g.Key.Text, Count = g.Count() })
            .ToListAsync(ct);
        if (muted.Count == 0) return popular;

        var byRange = muted.ToDictionary(m => (m.BlockId, m.StartOffset, m.EndOffset, m.Text), m => m.Count);
        return [.. popular.Select(p => byRange.TryGetValue((p.BlockId, p.StartOffset, p.EndOffset, p.Text), out var off) ? p with { Count = p.Count - off } : p)];
    }
}

internal sealed class GetMyHighlightsQueryHandler(IAppDbContext db, ICurrentUser viewer, HighlightTexts texts, IFileStorage storage)
    : IQueryHandler<GetMyHighlightsQuery, Result<CursorPage<HighlightGroupDto>>>
{
    /// <summary>Batches read to fill a page when groups drop out (every highlight hidden by an Update).</summary>
    private const int MaxRounds = 5;

    public async ValueTask<Result<CursorPage<HighlightGroupDto>>> Handle(GetMyHighlightsQuery query, CancellationToken ct)
    {
        var userId = viewer.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, 50);
        var after = HighlightGroupCursor.Decode(query.Cursor);
        var items = new List<HighlightGroupDto>();

        for (var round = 0; round < MaxRounds; round++)
        {
            var needed = limit - items.Count;
            var batch = await ReadGroupsAsync(userId, after, needed + 1, ct);
            var scanned = batch.Take(needed).ToList();
            if (scanned.Count == 0) return new CursorPage<HighlightGroupDto>(items, null);

            items.AddRange(await BuildAsync(userId, scanned, ct));
            after = scanned[^1];

            if (batch.Count <= needed) return new CursorPage<HighlightGroupDto>(items, null); // nothing after these
            if (items.Count == limit) break;
        }

        return new CursorPage<HighlightGroupDto>(items, after?.Encode());
    }

    private async Task<List<HighlightGroupCursor>> ReadGroupsAsync(Guid userId, HighlightGroupCursor? after, int take, CancellationToken ct)
    {
        // Articles you can still open: the reader's rules (your own hidden article stays yours to open).
        var openable = db.Articles.VisibleTo(viewer);
        var groups = db.ArticleHighlights.AsNoTracking()
            .Where(h => h.UserId == userId && openable.Any(a => a.Id == h.ArticleId))
            .GroupBy(h => new { h.ArticleId, h.Language })
            .Select(g => new { g.Key.ArticleId, g.Key.Language, LatestAt = g.Max(h => h.CreatedAt) });

        if (after is { } c)
        {
            groups = groups.Where(g => g.LatestAt < c.LatestAt
                || (g.LatestAt == c.LatestAt && (g.ArticleId.CompareTo(c.ArticleId) < 0
                    || (g.ArticleId == c.ArticleId && string.Compare(g.Language, c.Language) < 0))));
        }

        var rows = await groups
            .OrderByDescending(g => g.LatestAt)
            .ThenByDescending(g => g.ArticleId)
            .ThenByDescending(g => g.Language)
            .Take(take)
            .ToListAsync(ct);
        return [.. rows.Select(r => new HighlightGroupCursor(r.LatestAt, r.ArticleId, r.Language))];
    }

    private async Task<List<HighlightGroupDto>> BuildAsync(Guid userId, List<HighlightGroupCursor> groups, CancellationToken ct)
    {
        var ids = groups.Select(g => g.ArticleId).Distinct().ToList();
        var articles = (await db.Articles.AsNoTracking()
                .Where(a => ids.Contains(a.Id))
                .Select(a => new
                {
                    a.Id,
                    a.Slug,
                    Author = a.Author == null
                        ? null
                        : new AuthorDto(a.Author.Id, a.Author.DisplayName, a.Author.Username, a.Author.AvatarUrl, a.Author.IsVerified, a.Author.Headline),
                    Titles = a.Translations.Select(t => new { t.Language, t.Title }).ToList(),
                })
                .ToListAsync(ct))
            .ToDictionary(a => a.Id);

        var highlights = (await db.ArticleHighlights.AsNoTracking()
                .Where(h => h.UserId == userId && ids.Contains(h.ArticleId))
                .Select(h => new { h.ArticleId, h.Language, Dto = new HighlightDto(h.Id, h.BlockId, h.StartOffset, h.EndOffset, h.Text, h.CreatedAt) })
                .ToListAsync(ct))
            .ToLookup(h => (h.ArticleId, h.Language), h => h.Dto);

        // Every version of the page at once: from the cache, the rest in one query (no query per group).
        var versions = await texts.GetVersionsAsync(groups.Select(g => (g.ArticleId, g.Language)), ct);

        var result = new List<HighlightGroupDto>();
        foreach (var group in groups)
        {
            if (!articles.TryGetValue(group.ArticleId, out var article)) continue;
            if (article.Titles.FirstOrDefault(t => t.Language == group.Language) is not { } title) continue;
            if (!versions.TryGetValue((group.ArticleId, group.Language), out var version)) continue;

            var shown = highlights[(group.ArticleId, group.Language)]
                .Where(h => version.StillMatches(h.BlockId, h.StartOffset, h.EndOffset, h.Text))
                .OrderByDescending(h => h.CreatedAt)
                .ThenByDescending(h => h.Id)
                .ToList();
            if (shown.Count == 0) continue;

            var author = article.Author is null ? null : article.Author with { AvatarUrl = storage.ToPublicUrl(article.Author.AvatarUrl) };
            // latestAt is what the groups are ordered and paged by: the newest of your highlights on the version, also when
            // an Update hid it (whether one still matches is only known here, after the query that orders them).
            result.Add(new HighlightGroupDto(
                new HighlightArticleDto(article.Id, article.Slug, group.Language, title.Title, author),
                shown,
                group.LatestAt));
        }
        return result;
    }
}

/// <summary>Opaque keyset cursor over the Saved → Highlights groups: (newest highlight, article id, language), all DESC.</summary>
internal readonly record struct HighlightGroupCursor(DateTime LatestAt, Guid ArticleId, string Language)
{
    public string Encode() =>
        CursorText.Encode($"h:{LatestAt.Ticks.ToString(CultureInfo.InvariantCulture)}:{ArticleId:N}:{Language}");

    public static HighlightGroupCursor? Decode(string? cursor)
    {
        if (CursorText.Decode(cursor) is not ["h", var ticks, var id, var language] || !ArticleLanguages.IsValid(language)) return null;
        try
        {
            return new HighlightGroupCursor(
                new DateTime(long.Parse(ticks, NumberStyles.None, CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(id, "N"),
                language);
        }
        catch (Exception e) when (e is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
