using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Blocks;
using ReadIn.Application.Features.Mutes;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Search;

/// <summary>Who and what the people, topics and tags tabs can show (contract-v1 "Search").</summary>
internal static class SearchVisibility
{
    /// <summary>
    /// People search finds: deleted accounts are left out by the query filter, suspended ones (while suspended) and
    /// accounts that haven't completed their profile (the <c>@reader_…</c> placeholder) here. System accounts (the
    /// official ReadIn account) are found like everyone. The App Review account (SPEC §18.3) is never found: not in search,
    /// Explore's new writers or a field's top writers.
    /// </summary>
    public static IQueryable<User> Findable(this IQueryable<User> users, DateTime now) =>
        users.Where(u => u.IsProfileComplete && !u.IsReviewAccount && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)));

    /// <summary>
    /// Leaves out the writers <paramref name="viewerId"/> muted (SPEC F28): people search, Explore's new writers and a
    /// field's top writers. Guests keep everyone. Articles go through <c>ArticleVisibility.WithoutMutedFor</c>.
    /// </summary>
    public static IQueryable<User> WithoutMutedFor(this IQueryable<User> users, IAppDbContext db, Guid? viewerId)
    {
        if (viewerId is not { } viewer) return users;

        var muted = db.MutedUserIds(viewer);
        var blocked = db.BlockedWith(viewer);
        return users.Where(u => !muted.Contains(u.Id) && !blocked.Contains(u.Id));
    }

    /// <summary>
    /// Leaves out the people <paramref name="viewerId"/> is blocked with, either way (SPEC F36): followers and following
    /// lists, who reacted, mention suggestions. Guests keep everyone.
    /// </summary>
    public static IQueryable<User> WithoutBlockedFor(this IQueryable<User> users, IAppDbContext db, Guid? viewerId)
    {
        if (viewerId is not { } viewer) return users;

        var blocked = db.BlockedWith(viewer);
        return users.Where(u => !blocked.Contains(u.Id));
    }

    /// <summary>Leaves out the fields <paramref name="viewerId"/> muted (Explore's field tiles, topic search).</summary>
    public static IQueryable<Field> WithoutMutedFor(this IQueryable<Field> fields, IAppDbContext db, Guid? viewerId)
    {
        if (viewerId is not { } viewer) return fields;

        var muted = db.MutedIds(viewer, ContentMuteTarget.Field);
        return fields.Where(f => !muted.Contains(f.Id));
    }

    /// <summary>Leaves out the topics <paramref name="viewerId"/> muted, and those of the fields they muted (topic search).</summary>
    public static IQueryable<Topic> WithoutMutedFor(this IQueryable<Topic> topics, IAppDbContext db, Guid? viewerId)
    {
        if (viewerId is not { } viewer) return topics;

        var mutedTopics = db.MutedIds(viewer, ContentMuteTarget.Topic);
        var mutedFields = db.MutedIds(viewer, ContentMuteTarget.Field);
        return topics.Where(t => !mutedTopics.Contains(t.Id) && !mutedFields.Contains(t.FieldId));
    }
}
