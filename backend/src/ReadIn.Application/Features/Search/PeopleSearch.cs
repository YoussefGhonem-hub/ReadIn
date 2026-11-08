using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Follows;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// <c>GET /search?type=users</c> (contract-v1 "Search"): people whose display name holds every word of <see cref="Q"/>
/// at the start of a word, or whose @username starts with it. Exact matches first, then prefixes; then verified writers
/// and the most followed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record UserSearchQuery(string? Q, string? Cursor, int Limit) : IQuery<Result<CursorPage<UserSummaryDto>>>;

/// <summary>
/// Names aren't stored normalized, so both engines match them the same way: §22 normalization in SQL
/// (<see cref="ArabicNormalizer.InSql"/>) and escaped <c>LIKE</c> patterns. The table is small next to the articles'.
/// </summary>
public sealed class PeopleSearch(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, TimeProvider clock)
{
    public async Task<(List<UserSummaryDto> Page, string? Next)> FindAsync(SearchTerms terms, string? cursor, int limit, CancellationToken ct)
    {
        var (offset, take, size) = SearchPaging.Window(cursor, limit);
        if (take == 0) return ([], null);

        var viewerId = currentUser.UserId;
        var users = db.Users.AsNoTracking().Findable(clock.GetUtcNow().UtcDateTime).WithoutMutedFor(db, viewerId);

        var byName = users;
        foreach (var word in terms.Words)
        {
            var (plain, withArticle) = SearchTerms.WordStartPatterns(word);
            byName = byName.Where(u =>
                EF.Functions.Like(" " + ArabicNormalizer.InSql(u.DisplayName), plain, SearchTerms.LikeEscape)
                || EF.Functions.Like(" " + ArabicNormalizer.InSql(u.DisplayName), withArticle, SearchTerms.LikeEscape));
        }

        var nameMatches = byName.Select(u => u.Id);
        var handle = terms.Handle ?? string.Empty;
        // LIKE '' matches no username, so without a handle only the display name counts.
        var handlePrefix = terms.Handle is null ? string.Empty : SearchTerms.EscapeLike(terms.Handle) + "%";
        var phrase = terms.Phrase;
        var phrasePrefix = SearchTerms.EscapeLike(phrase) + "%";

        var ids = await users
            .Where(u => nameMatches.Contains(u.Id) || EF.Functions.Like(u.Username, handlePrefix, SearchTerms.LikeEscape))
            .Select(u => new
            {
                u.Id,
                u.Username,
                Tier = u.Username == handle || ArabicNormalizer.InSql(u.DisplayName) == phrase ? 0
                    : EF.Functions.Like(u.Username, handlePrefix, SearchTerms.LikeEscape)
                      || EF.Functions.Like(ArabicNormalizer.InSql(u.DisplayName), phrasePrefix, SearchTerms.LikeEscape) ? 1
                    : 2,
                Verified = u.IsVerified,
                Followers = db.UserFollows.Count(f => f.FolloweeId == u.Id && !db.Users.Any(r => r.Id == f.FollowerId && r.IsReviewAccount)),
            })
            .OrderBy(u => u.Tier)
            .ThenByDescending(u => u.Verified)
            .ThenByDescending(u => u.Followers)
            .ThenBy(u => u.Username)
            .ThenBy(u => u.Id)
            .Skip(offset)
            .Take(take)
            .Select(u => u.Id)
            .ToListAsync(ct);

        var (pageIds, next) = SearchPaging.Cut(ids, offset, size);
        if (pageIds.Count == 0) return ([], next);

        var summaries = await db.Users.AsNoTracking()
            .Where(u => pageIds.Contains(u.Id))
            .Select(UserSummaries.For(db, viewerId))
            .ToDictionaryAsync(u => u.Id, ct);
        return (pageIds.Where(summaries.ContainsKey).Select(id => summaries[id].WithPublicUrls(storage)).ToList(), next);
    }
}

internal sealed class UserSearchQueryHandler(PeopleSearch people) : IQueryHandler<UserSearchQuery, Result<CursorPage<UserSummaryDto>>>
{
    public async ValueTask<Result<CursorPage<UserSummaryDto>>> Handle(UserSearchQuery query, CancellationToken ct)
    {
        var terms = SearchTerms.Parse(query.Q);
        if (terms.IsFailure) return terms.Error!;

        var (page, next) = await people.FindAsync(terms.Value, query.Cursor, query.Limit, ct);
        return new CursorPage<UserSummaryDto>(page, next);
    }
}
