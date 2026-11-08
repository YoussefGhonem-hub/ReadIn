using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Mutes;

/// <summary>A viewer's mutes and "show less" marks as SQL subqueries and reads (SPEC F28).</summary>
internal static class MuteState
{
    /// <summary>The writers <paramref name="viewerId"/> muted.</summary>
    public static IQueryable<Guid> MutedUserIds(this IAppDbContext db, Guid viewerId) =>
        db.UserMutes.Where(m => m.MuterId == viewerId).Select(m => m.MutedUserId);

    /// <summary>The fields (or topics) <paramref name="viewerId"/> muted.</summary>
    public static IQueryable<Guid> MutedIds(this IAppDbContext db, Guid viewerId, ContentMuteTarget target) =>
        db.ContentMutes.Where(m => m.UserId == viewerId && m.TargetType == target).Select(m => m.TargetId);

    /// <summary>The articles <paramref name="viewerId"/> marked "show less".</summary>
    public static IQueryable<Guid> ShownLessIds(this IAppDbContext db, Guid viewerId) =>
        db.ArticleFeedback.Where(f => f.UserId == viewerId && f.Type == ArticleFeedbackType.ShowLess).Select(f => f.ArticleId);

    public static async Task<ContentMutesDto> ContentMutesAsync(this IAppDbContext db, Guid userId, CancellationToken ct)
    {
        var mutes = await db.ContentMutes.AsNoTracking()
            .Where(m => m.UserId == userId)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new { m.TargetType, m.TargetId })
            .ToListAsync(ct);
        return new ContentMutesDto(
            [.. mutes.Where(m => m.TargetType == ContentMuteTarget.Field).Select(m => m.TargetId)],
            [.. mutes.Where(m => m.TargetType == ContentMuteTarget.Topic).Select(m => m.TargetId)]);
    }

    public static async Task<UserMuteStateDto> UserMuteStateAsync(
        this IAppDbContext db, Guid viewerId, Guid userId, bool followRemoved, CancellationToken ct) => new(
        await db.UserMutes.AnyAsync(m => m.MuterId == viewerId && m.MutedUserId == userId, ct),
        await db.UserFollows.AnyAsync(f => f.FollowerId == viewerId && f.FolloweeId == userId, ct),
        await db.UserFollows.CountAsync(f => f.FolloweeId == userId && !db.Users.Any(r => r.Id == f.FollowerId && r.IsReviewAccount), ct),
        followRemoved);

    /// <summary>
    /// The topics and fields lowered in For you for <paramref name="viewerId"/> (SPEC F28): those of the articles marked
    /// "show less" in the last 90 days; an article's topic, or its field when it has no topic.
    /// </summary>
    public static async Task<(List<Guid> TopicIds, List<Guid> FieldIds)> LoweredAsync(
        this IAppDbContext db, Guid viewerId, DateTime now, CancellationToken ct)
    {
        var since = now - ArticleFeedback.LoweredFor;
        var marked = await db.ArticleFeedback.AsNoTracking()
            .Where(f => f.UserId == viewerId && f.Type == ArticleFeedbackType.ShowLess && f.CreatedAt >= since)
            .Join(db.Articles, f => f.ArticleId, a => a.Id, (f, a) => new { a.FieldId, a.TopicId })
            .Distinct()
            .ToListAsync(ct);
        return (
            [.. marked.Where(m => m.TopicId != null).Select(m => m.TopicId!.Value).Distinct()],
            [.. marked.Where(m => m.TopicId == null).Select(m => m.FieldId).Distinct()]);
    }
}
