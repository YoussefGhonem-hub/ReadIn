using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Follows;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes.Queries.GetMutes;

internal sealed class GetMutesQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetMutesQuery, Result<MutesDto>>
{
    public async ValueTask<Result<MutesDto>> Handle(GetMutesQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var english = UiLanguages.Normalize(query.UiLanguage) == UiLanguages.English;

        // Deleted accounts are gone (their mutes are deleted with them); suspended ones stay listed.
        var users = await db.UserMutes.AsNoTracking()
            .Where(m => m.MuterId == userId)
            .OrderByDescending(m => m.CreatedAt)
            .ThenByDescending(m => m.Id)
            .Select(m => m.MutedUser)
            .Select(UserSummaries.For(db, userId))
            .ToListAsync(cancellationToken);

        var mutes = db.ContentMutes.AsNoTracking().Where(m => m.UserId == userId);
        var fields = await (
                from m in mutes
                where m.TargetType == ContentMuteTarget.Field
                join f in db.Fields on m.TargetId equals f.Id
                orderby m.CreatedAt descending, m.Id descending
                select new MutedFieldDto(f.Id, f.Slug, english ? f.NameEn : f.NameAr, f.NameAr, f.NameEn, f.Icon, f.Color))
            .ToListAsync(cancellationToken);

        var topics = await (
                from m in mutes
                where m.TargetType == ContentMuteTarget.Topic
                join t in db.Topics on m.TargetId equals t.Id
                join f in db.Fields on t.FieldId equals f.Id
                orderby m.CreatedAt descending, m.Id descending
                select new MutedTopicDto(
                    t.Id, t.Slug, english ? t.NameEn : t.NameAr, t.NameAr, t.NameEn,
                    new MutedFieldDto(f.Id, f.Slug, english ? f.NameEn : f.NameAr, f.NameAr, f.NameEn, f.Icon, f.Color)))
            .ToListAsync(cancellationToken);

        return new MutesDto([.. users.Select(u => u.WithPublicUrls(storage))], fields, topics);
    }
}
