using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Profiles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Reposts;

/// <summary>
/// GET /users/{username}/reposts — the profile's Reposts tab (SPEC F29, F14): the articles the user reposted that readers
/// can open, newest repost first, keyset-paginated over (repost time DESC, repost id DESC). Each card carries the label
/// with the user (<see cref="ArticleCardDto.RepostedBy"/>). Like the other profile tabs it keeps what the viewer muted.
/// Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfileRepostsQuery(string Username, string? Cursor, int Limit, string UiLanguage)
    : IQuery<Result<CursorPage<ArticleCardDto>>>;

internal sealed class GetProfileRepostsQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    IFileStorage storage,
    TimeProvider clock)
    : IQueryHandler<GetProfileRepostsQuery, Result<CursorPage<ArticleCardDto>>>
{
    public async ValueTask<Result<CursorPage<ArticleCardDto>>> Handle(GetProfileRepostsQuery query, CancellationToken ct)
    {
        if (await db.FindProfileAsync(query.Username, clock.GetUtcNow().UtcDateTime, ct) is not { } owner) return UserErrors.NotFound;

        var limit = Math.Clamp(query.Limit, 1, 50);
        var visible = db.Articles.Visible().Where(a => a.PublishedAt != null);
        var reposts = db.Reposts.AsNoTracking().Where(r => r.UserId == owner.Id && visible.Any(a => a.Id == r.ArticleId));

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
        {
            reposts = reposts.Where(r => r.CreatedAt < cursor.Timestamp || (r.CreatedAt == cursor.Timestamp && r.Id.CompareTo(cursor.Id) < 0));
        }

        var page = await reposts
            .OrderByDescending(r => r.CreatedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit + 1)
            .Select(r => new { r.Id, r.ArticleId, r.CreatedAt, r.Caption })
            .ToListAsync(ct);

        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].CreatedAt, page[^1].Id).Encode();
        }
        if (page.Count == 0) return new CursorPage<ArticleCardDto>([], next);

        var reposter = await db.Users.AsNoTracking()
            .Where(u => u.Id == owner.Id)
            .Select(u => new AuthorDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified, u.Headline))
            .FirstAsync(ct);
        reposter = reposter with { AvatarUrl = storage.ToPublicUrl(reposter.AvatarUrl) };

        var articleLanguage = currentUser.UserId is { } viewerId
            ? await db.Users.AsNoTracking().Where(u => u.Id == viewerId).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct)
            : ArticleLanguages.ForUi(query.UiLanguage);
        using var _ = LocalizedProjection.Begin(query.UiLanguage, articleLanguage);

        var ids = page.Select(p => p.ArticleId).ToList();
        var byId = (await db.Articles.AsNoTracking()
                .Where(a => ids.Contains(a.Id))
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct))
            .ToDictionary(c => c.Id);

        var ordered = page.Where(p => byId.ContainsKey(p.ArticleId)).ToList();
        var completed = await cards.CompleteAsync([.. ordered.Select(p => byId[p.ArticleId])], ct);
        return new CursorPage<ArticleCardDto>(
            [.. completed.Select((card, i) => card with { RepostedBy = new RepostLabelDto(reposter, 0, ordered[i].CreatedAt, ordered[i].Caption) })],
            next);
    }
}

/// <summary>
/// GET /articles/{id}/repost (SPEC F29): your repost of an article you can open, with its caption; it prefills "Edit your
/// thoughts". Not reposted: <c>isReposted: false</c> and no caption. Same 404 rules as the writes.
/// </summary>
[Authenticated]
public sealed record GetRepostStateQuery(Guid ArticleId) : IQuery<Result<RepostStateDto>>;

internal sealed class GetRepostStateQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetRepostStateQuery, Result<RepostStateDto>>
{
    public async ValueTask<Result<RepostStateDto>> Handle(GetRepostStateQuery query, CancellationToken ct)
    {
        if (!await db.Articles.AsNoTracking().VisibleTo(currentUser).AnyAsync(a => a.Id == query.ArticleId, ct)) return ArticleErrors.NotFound;
        return await RepostStates.ReadAsync(db, currentUser.RequireUserId(), query.ArticleId, ct);
    }
}
