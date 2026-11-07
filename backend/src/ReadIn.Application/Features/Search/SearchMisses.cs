using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Admin;

namespace ReadIn.Application.Features.Search;

/// <summary>A search that found nothing, waiting to be counted (SPEC §22, F23).</summary>
/// <param name="Query">The cleaned, normalized query (≤ 100 characters).</param>
/// <param name="Language"><c>ar</c> or <c>en</c> (<see cref="SearchMissBuffer.LanguageOf"/>).</param>
/// <param name="Date">The day of the search in <c>Admin:TimeZone</c>.</param>
/// <param name="At">When it was searched (UTC); a pending miss is counted <see cref="SearchMissBuffer.Hold"/> later.</param>
public sealed record SearchMissEntry(string Query, string Language, DateOnly Date, DateTime At);

/// <summary>
/// Searches with no results (contract-v1 "Admin console", decision 8). Clients search as you type, so a miss isn't counted
/// at once: each searcher (a user, or a guest's IP) has at most one pending miss, held <see cref="Hold"/>. The searcher's
/// next search drops it when it extends it (<c>dock</c> → <c>docker</c>, or the same query again) and lets it be counted
/// otherwise. Nothing here knows who searched once it is counted: <see cref="SearchMissWriter"/> stores only the query,
/// its language, the day and a count. In memory: a restart loses at most the misses still held.
/// </summary>
public sealed class SearchMissBuffer
{
    /// <summary>How long a miss waits for the same searcher's next keystrokes.</summary>
    public static readonly TimeSpan Hold = TimeSpan.FromSeconds(30);

    private readonly ConcurrentDictionary<string, SearchMissEntry> _pending = new(StringComparer.Ordinal);
    private readonly ConcurrentQueue<SearchMissEntry> _ready = new();

    /// <summary>
    /// A first page of article search by <paramref name="searcher"/>: drops their pending miss when <paramref name="query"/>
    /// extends it, readies it to be counted otherwise, and holds <paramref name="query"/> when it found nothing.
    /// </summary>
    public void Observe(string searcher, string query, DateOnly date, DateTime now, bool missed)
    {
        if (_pending.TryRemove(searcher, out var pending) && !query.StartsWith(pending.Query, StringComparison.Ordinal))
            _ready.Enqueue(pending);
        if (missed) _pending[searcher] = new SearchMissEntry(query, LanguageOf(query), date, now);
    }

    /// <summary>The misses to count now: those readied, and those held for <see cref="Hold"/> or longer.</summary>
    public IReadOnlyList<SearchMissEntry> TakeDue(DateTime now)
    {
        var due = new List<SearchMissEntry>();
        while (_ready.TryDequeue(out var entry)) due.Add(entry);
        foreach (var (searcher, entry) in _pending)
        {
            if (now - entry.At >= Hold && ((ICollection<KeyValuePair<string, SearchMissEntry>>)_pending).Remove(new(searcher, entry)))
                due.Add(entry);
        }
        return due;
    }

    /// <summary>Every miss, held or not (at shutdown, and in tests).</summary>
    public IReadOnlyList<SearchMissEntry> TakeAll() => TakeDue(DateTime.MaxValue);

    /// <summary><c>ar</c> when the query holds an Arabic letter, else <c>en</c>.</summary>
    public static string LanguageOf(string query) =>
        query.Any(c => (c is (>= '؀' and <= 'ۿ') or (>= 'ݐ' and <= 'ݿ') or (>= 'ࢠ' and <= 'ࣿ')) && char.IsLetter(c))
            ? "ar"
            : "en";
}

/// <summary>Adds misses to <c>SearchMisses</c>: one row per day, language and query, counted (SPEC §22).</summary>
public sealed class SearchMissWriter(IAppDbContext db)
{
    public async Task WriteAsync(IReadOnlyList<SearchMissEntry> misses, CancellationToken ct)
    {
        var groups = misses
            .Where(m => m.Query.Length is > 0 and <= SearchMiss.MaxQueryLength)
            .GroupBy(m => (m.Date, m.Language, m.Query))
            .Select(g => (g.Key.Date, g.Key.Language, g.Key.Query, Count: g.Count()));
        foreach (var (date, language, query, count) in groups)
        {
            if (await IncrementAsync(date, language, query, count, ct)) continue;
            db.SearchMisses.Add(new SearchMiss(date, language, query, count));
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException)
            {
                // Another writer added the row first: add to it instead.
                db.ClearChangeTracker();
                await IncrementAsync(date, language, query, count, ct);
            }
        }
    }

    private async Task<bool> IncrementAsync(DateOnly date, string language, string query, int count, CancellationToken ct) =>
        await db.SearchMisses
            .Where(m => m.Date == date && m.Language == language && m.Query == query)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.Count, m => m.Count + count), ct) > 0;
}
