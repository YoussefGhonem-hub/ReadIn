using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Highlights;

/// <summary>
/// One published article version as highlights see it (SPEC F30): its blocks' plain text, plus what decides who may see
/// it. The same for every reader, so it is cached once; whether a hidden article is shown is decided per caller.
/// </summary>
public sealed record HighlightVersion(Guid ArticleId, Guid? AuthorId, bool IsHidden, string Language, IReadOnlyList<RDocTextBlock> Blocks)
{
    public RDocTextBlock? Find(string blockId) => Blocks.FirstOrDefault(b => b.Id == blockId);

    /// <summary>A highlight still marks its text: after an Update, one whose text moved or changed is not shown (SPEC F30).</summary>
    public bool StillMatches(string blockId, int startOffset, int endOffset, string text) =>
        Find(blockId) is { } block && HighlightRanges.Matches(block, startOffset, endOffset, text);

    /// <summary>Document order: the block's position, then the offsets.</summary>
    public (int Block, int Start, int End) OrderKey(string blockId, int startOffset, int endOffset)
    {
        var index = -1;
        for (var i = 0; i < Blocks.Count; i++)
        {
            if (Blocks[i].Id == blockId)
            {
                index = i;
                break;
            }
        }
        return (index, startOffset, endOffset);
    }
}

/// <summary>The popular ranges of one version, for everyone (no viewer's mutes applied yet).</summary>
public sealed record PopularRanges(IReadOnlyList<PopularHighlightDto> Ranges);

/// <summary>Range checks on a block's plain text (SPEC F30; <c>shared/rdoc/highlight-fixtures.json</c>).</summary>
public static class HighlightRanges
{
    /// <summary>
    /// The block can be highlighted and its plain text at [start, end) is exactly <paramref name="text"/>, inside one unit
    /// (a list item never runs into the next) and without splitting a surrogate pair.
    /// </summary>
    public static bool Matches(RDocTextBlock block, int start, int end, string text)
    {
        if (block.Text is not { } plain) return false;
        if (start < 0 || end <= start || end > plain.Length) return false;
        if (!block.Units.Any(u => u.Start <= start && end <= u.End)) return false;
        if (SplitsPair(plain, start) || SplitsPair(plain, end)) return false;
        return end - start == text.Length && string.CompareOrdinal(plain, start, text, 0, text.Length) == 0;
    }

    /// <summary>Drops whitespace at both ends of [start, end) of <paramref name="plain"/>.</summary>
    public static (int Start, int End) Trim(string plain, int start, int end)
    {
        while (start < end && IsWhiteSpace(plain[start])) start++;
        while (end > start && IsWhiteSpace(plain[end - 1])) end--;
        return (start, end);
    }

    /// <summary>Unicode White_Space, the exact set the clients trim (contract "Highlights (F30)").</summary>
    public static bool IsWhiteSpace(char c) => (int)c is (>= 0x09 and <= 0x0D) or 0x20 or 0x85 or 0xA0 or 0x1680
        or (>= 0x2000 and <= 0x200A) or 0x2028 or 0x2029 or 0x202F or 0x205F or 0x3000;

    private static bool SplitsPair(string s, int i) => i > 0 && i < s.Length && char.IsHighSurrogate(s[i - 1]) && char.IsLowSurrogate(s[i]);
}

/// <summary>
/// The shared, cached parts of the reader's highlights (SPEC F30): each version's block texts and its popular ranges.
/// Neither holds anything about a viewer; "mine" and the viewer's mutes are read per request.
/// </summary>
public sealed class HighlightTexts(IAppDbContext db, HybridCache cache)
{
    /// <summary>Ranges that reach the threshold before a viewer's mutes are taken off; enough for the top 5 after.</summary>
    internal const int PopularCandidates = 100;

    internal const int PopularThreshold = 3;
    internal const int PopularShown = 5;

    private static readonly TimeSpan Expiration = TimeSpan.FromMinutes(10);

    private static readonly HybridCacheEntryOptions VersionOptions = new() { Expiration = Expiration, LocalCacheExpiration = Expiration };

    /// <summary>Reads the cache only: never loads, never writes (a miss is null).</summary>
    private static readonly HybridCacheEntryOptions CacheOnly = new()
    {
        Flags = HybridCacheEntryFlags.DisableUnderlyingData | HybridCacheEntryFlags.DisableLocalCacheWrite | HybridCacheEntryFlags.DisableDistributedCacheWrite,
    };

    private static string VersionKey(Guid articleId, string? language) => $"highlight-version:{articleId}:{language ?? "source"}";

    private static string[] VersionTags(Guid articleId) => [CacheTags.ArticleById(articleId), CacheTags.Articles];

    /// <summary>
    /// The version <paramref name="language"/> of a published article, or its source language when that version doesn't
    /// exist or <paramref name="language"/> is null. Null for an unknown, unpublished or deleted article. Hidden ones are
    /// returned: the caller decides.
    /// </summary>
    public async Task<HighlightVersion?> GetVersionAsync(Guid articleId, string? language, CancellationToken ct)
    {
        language = ArticleLanguages.IsValid(language) ? language : null;
        try
        {
            return await cache.GetOrCreateAsync(
                VersionKey(articleId, language),
                (Db: db, ArticleId: articleId, Language: language),
                static async (state, token) => await LoadVersionAsync(state.Db, state.ArticleId, state.Language, token) ?? throw new VersionNotFoundException(),
                VersionOptions,
                VersionTags(articleId),
                ct);
        }
        catch (VersionNotFoundException)
        {
            return null; // never cached
        }
    }

    /// <summary>
    /// Exactly these versions, for a list (Saved → Highlights): the cached ones from the cache, the rest in one query,
    /// then cached for the reader too. A pair that isn't there (no such version, unpublished, deleted) is left out.
    /// </summary>
    public async Task<IReadOnlyDictionary<(Guid ArticleId, string Language), HighlightVersion>> GetVersionsAsync(
        IEnumerable<(Guid ArticleId, string Language)> versions, CancellationToken ct)
    {
        var found = new Dictionary<(Guid ArticleId, string Language), HighlightVersion>();
        var missing = new HashSet<(Guid ArticleId, string Language)>();
        foreach (var key in versions.Distinct())
        {
            var cached = await cache.GetOrCreateAsync(
                VersionKey(key.ArticleId, key.Language),
                static _ => ValueTask.FromResult<HighlightVersion?>(null),
                CacheOnly,
                cancellationToken: ct);
            if (cached is null) missing.Add(key);
            else if (cached.Language == key.Language) found[key] = cached;
            // Otherwise the cache holds the source in place of a version that doesn't exist: left out.
        }
        if (missing.Count == 0) return found;

        var ids = missing.Select(k => k.ArticleId).Distinct().ToList();
        var languages = missing.Select(k => k.Language).Distinct().ToList();
        var rows = await db.Articles.AsNoTracking()
            .Published()
            .Where(a => ids.Contains(a.Id))
            .SelectMany(
                a => a.Translations.Where(t => languages.Contains(t.Language)),
                (a, t) => new { a.Id, a.AuthorId, IsHidden = a.HiddenAt != null, t.Language, t.ContentJson })
            .ToListAsync(ct);

        foreach (var row in rows)
        {
            if (!missing.Contains((row.Id, row.Language))) continue;
            var version = new HighlightVersion(row.Id, row.AuthorId, row.IsHidden, row.Language, RDocBlockText.Blocks(row.ContentJson));
            await cache.SetAsync(VersionKey(row.Id, row.Language), version, VersionOptions, VersionTags(row.Id), ct);
            found[(row.Id, row.Language)] = version;
        }
        return found;
    }

    /// <summary>Ranges at least 3 readers marked on the version, still matching its text, most marked first (≤ 100).</summary>
    public async Task<IReadOnlyList<PopularHighlightDto>> GetPopularAsync(HighlightVersion version, CancellationToken ct)
    {
        var popular = await cache.GetOrCreateAsync(
            $"highlight-popular:{version.ArticleId}:{version.Language}",
            (Db: db, Version: version),
            static async (state, token) => new PopularRanges(await LoadPopularAsync(state.Db, state.Version, token)),
            new HybridCacheEntryOptions { Expiration = Expiration, LocalCacheExpiration = Expiration },
            [CacheTags.ArticleHighlights(version.ArticleId), CacheTags.ArticleById(version.ArticleId)],
            ct);
        return popular.Ranges;
    }

    /// <summary>
    /// <see cref="GetVersionAsync"/> straight from the database: writes check the text as it is now, and the cache
    /// fills from here.
    /// </summary>
    public static async Task<HighlightVersion?> LoadVersionAsync(IAppDbContext db, Guid articleId, string? language, CancellationToken ct)
    {
        var article = await db.Articles.AsNoTracking()
            .Published()
            .Where(a => a.Id == articleId)
            .Select(a => new
            {
                a.AuthorId,
                IsHidden = a.HiddenAt != null,
                Versions = a.Translations
                    .Where(t => t.Language == language || t.IsSource)
                    .Select(t => new { t.Language, t.IsSource, t.ContentJson })
                    .ToList(),
            })
            .FirstOrDefaultAsync(ct);

        var version = article?.Versions.FirstOrDefault(v => v.Language == language) ?? article?.Versions.FirstOrDefault(v => v.IsSource);
        if (article is null || version is null) return null;

        return new HighlightVersion(articleId, article.AuthorId, article.IsHidden, version.Language, RDocBlockText.Blocks(version.ContentJson));
    }

    private static async Task<IReadOnlyList<PopularHighlightDto>> LoadPopularAsync(IAppDbContext db, HighlightVersion version, CancellationToken ct)
    {
        // Grouped by the whole range, text included: the same offsets with an older text (before an Update) is another range.
        var groups = await db.ArticleHighlights.AsNoTracking()
            .Where(h => h.ArticleId == version.ArticleId && h.Language == version.Language)
            .GroupBy(h => new { h.BlockId, h.StartOffset, h.EndOffset, h.Text })
            .Select(g => new { g.Key.BlockId, g.Key.StartOffset, g.Key.EndOffset, g.Key.Text, Count = g.Count() })
            .Where(g => g.Count >= PopularThreshold)
            .OrderByDescending(g => g.Count)
            .Take(PopularCandidates)
            .ToListAsync(ct);

        return [.. groups
            .Where(g => version.StillMatches(g.BlockId, g.StartOffset, g.EndOffset, g.Text))
            .Select(g => new PopularHighlightDto(g.BlockId, g.StartOffset, g.EndOffset, g.Text, g.Count))];
    }

    private sealed class VersionNotFoundException : Exception;
}
