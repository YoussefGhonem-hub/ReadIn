using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// <c>GET /search?type=tags</c> (contract-v1 "Search"): visible tags with at least one visible article whose name holds
/// every word of <see cref="Q"/> at the start of a word (after a space, <c>-</c>, <c>_</c> or <c>.</c>), or whose slug
/// starts with its slug. The exact name first, then the most used.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record TagSearchQuery(string? Q, string? Cursor, int Limit) : IQuery<Result<CursorPage<TagDto>>>;

/// <summary><c>Tags.NormalizedName</c> is stored normalized (F32 rule 3), so it is matched as it is, with escaped LIKE patterns.</summary>
public sealed class TagSearch(IAppDbContext db)
{
    public async Task<(List<TagDto> Page, string? Next)> FindAsync(SearchTerms terms, string? cursor, int limit, CancellationToken ct)
    {
        var (offset, take, size) = SearchPaging.Window(cursor, limit);
        if (take == 0) return ([], null);

        var tags = db.Tags.AsNoTracking().Where(t => !t.IsHidden);
        var byWords = tags;
        foreach (var word in terms.Words)
        {
            var (space, spaceArticle) = SearchTerms.WordStartPatterns(word);
            var (dash, _) = SearchTerms.WordStartPatterns(word, '-');
            var (underscore, _) = SearchTerms.WordStartPatterns(word, '_');
            var (dot, _) = SearchTerms.WordStartPatterns(word, '.');
            byWords = byWords.Where(t =>
                EF.Functions.Like(" " + t.NormalizedName, space, SearchTerms.LikeEscape)
                || EF.Functions.Like(" " + t.NormalizedName, spaceArticle, SearchTerms.LikeEscape)
                || EF.Functions.Like(t.NormalizedName, dash, SearchTerms.LikeEscape)
                || EF.Functions.Like(t.NormalizedName, underscore, SearchTerms.LikeEscape)
                || EF.Functions.Like(t.NormalizedName, dot, SearchTerms.LikeEscape));
        }

        var wordMatches = byWords.Select(t => t.Id);
        // LIKE '' matches no slug, so a query that gives no slug matches by name only.
        var slugPrefix = terms.Slug.Length == 0 ? string.Empty : SearchTerms.EscapeLike(terms.Slug) + "%";
        var phrase = terms.Phrase;
        // Hidden and deleted articles count for nothing, like everywhere readers look (F32).
        var published = db.Articles.Visible().Where(a => a.PublishedAt != null);

        var rows = await tags
            .Where(t => wordMatches.Contains(t.Id) || EF.Functions.Like(t.Slug, slugPrefix, SearchTerms.LikeEscape))
            .Select(t => new
            {
                t.Slug,
                t.Name,
                Exact = t.NormalizedName == phrase,
                Count = published.Count(a => a.Tags.Any(x => x.TagId == t.Id)),
            })
            .Where(t => t.Count > 0)
            .OrderByDescending(t => t.Exact)
            .ThenByDescending(t => t.Count)
            .ThenBy(t => t.Name)
            .ThenBy(t => t.Slug)
            .Skip(offset)
            .Take(take)
            .ToListAsync(ct);

        var (page, next) = SearchPaging.Cut(rows, offset, size);
        return (page.Select(t => new TagDto(t.Slug, t.Name, t.Count)).ToList(), next);
    }
}

internal sealed class TagSearchQueryHandler(TagSearch tags) : IQueryHandler<TagSearchQuery, Result<CursorPage<TagDto>>>
{
    public async ValueTask<Result<CursorPage<TagDto>>> Handle(TagSearchQuery query, CancellationToken ct)
    {
        var terms = SearchTerms.Parse(query.Q);
        if (terms.IsFailure) return terms.Error!;

        var (page, next) = await tags.FindAsync(terms.Value, query.Cursor, query.Limit, ct);
        return new CursorPage<TagDto>(page, next);
    }
}
