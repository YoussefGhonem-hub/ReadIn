using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Profiles.Queries.GetProfile;

/// <summary>
/// GET /users/{username} — the public profile (SPEC F14). <see cref="Username"/> is matched ignoring case and a
/// leading <c>@</c>; deleted and suspended accounts are <c>user.not_found</c>. Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetProfileQuery(string Username) : IQuery<Result<ProfileDto>>;

internal sealed class GetProfileQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, TimeProvider clock)
    : IQueryHandler<GetProfileQuery, Result<ProfileDto>>
{
    public async ValueTask<Result<ProfileDto>> Handle(GetProfileQuery query, CancellationToken cancellationToken)
    {
        if (ProfileUsers.Handle(query.Username) is not { } handle) return UserErrors.NotFound;

        var user = await db.Users.AsNoTracking()
            .Shown(handle, clock.GetUtcNow().UtcDateTime)
            .FirstOrDefaultAsync(cancellationToken);
        if (user is null) return UserErrors.NotFound;

        var isMe = currentUser.UserId == user.Id;
        // No user has the empty id, so guests and your own profile get false without a second query shape.
        var viewer = isMe ? Guid.Empty : currentUser.UserId ?? Guid.Empty;
        var published = db.Articles.Visible().Where(a => a.AuthorId == user.Id && a.PublishedAt != null);
        var facts = await db.Users.AsNoTracking()
            .Where(u => u.Id == user.Id)
            .Select(u => new
            {
                IsVerified = u.IsVerified,
                Articles = published.Count(),
                TotalReads = published.Sum(a => a.ReadCount),
                Followers = db.UserFollows.Count(f => f.FolloweeId == u.Id),
                Following = db.UserFollows.Count(f => f.FollowerId == u.Id),
                IsFollowing = db.UserFollows.Any(f => f.FollowerId == viewer && f.FolloweeId == u.Id),
                FollowsYou = db.UserFollows.Any(f => f.FollowerId == u.Id && f.FolloweeId == viewer),
                // F28: "انت كاتم الكاتب ده" with "إلغاء الكتم"; the profile still lists their articles.
                IsMuted = db.UserMutes.Any(m => m.MuterId == viewer && m.MutedUserId == u.Id),
            })
            .FirstAsync(cancellationToken);

        var arabic = currentUser.UiLanguage == UiLanguages.Arabic;
        var expertise = await db.Users.AsNoTracking()
            .Where(u => u.Id == user.Id)
            .SelectMany(u => u.Expertise)
            .Join(db.Fields.Where(f => f.IsEnabled), e => e.FieldId, f => f.Id, (e, f) => new
            {
                e.Position, f.Id, f.Slug, Name = arabic ? f.NameAr : f.NameEn, f.Icon, f.Color,
            })
            .OrderBy(x => x.Position)
            .Select(x => new ExpertiseFieldDto(x.Id, x.Slug, x.Name, x.Icon, x.Color))
            .ToListAsync(cancellationToken);

        var variants = await db.LoadVariantsAsync(user.Id, user.AvatarUrl, cancellationToken);

        return new ProfileDto(
            user.Id,
            user.DisplayName,
            user.Username,
            storage.ToPublicUrl(user.AvatarUrl),
            Avatars.Slots(variants, storage),
            facts.IsVerified,
            user.Bio,
            new UserLinksDto(user.Links.GitHub, user.Links.LinkedIn, user.Links.Website),
            expertise,
            user.CreatedAt,
            new ProfileStatsDto(facts.Articles, facts.Followers, facts.Following, facts.TotalReads),
            isMe,
            facts.IsFollowing,
            facts.FollowsYou,
            new ProfileOwner(user.Id, user.PublicReadingStats).ReadingStatsVisibleTo(currentUser.UserId))
        {
            IsMuted = facts.IsMuted,
            IsSystemAccount = user.IsSystemAccount,
        };
    }
}
