using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Search;

/// <summary>Who and what the people, topics and tags tabs can show (contract-v1 "Search").</summary>
internal static class SearchVisibility
{
    /// <summary>
    /// People search finds: deleted accounts are left out by the query filter, suspended ones (while suspended) and
    /// accounts that haven't completed their profile (the <c>@reader_…</c> placeholder) here. System accounts (the
    /// official ReadIn account) are found like everyone.
    /// </summary>
    public static IQueryable<User> Findable(this IQueryable<User> users, DateTime now) =>
        users.Where(u => u.IsProfileComplete && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)));

    /// <summary>
    /// The seam for F28 (mute): leaves out the writers <paramref name="viewerId"/> muted. F28 isn't built yet, so nothing
    /// is left out. Articles go through <c>ArticleVisibility.WithoutMutedFor</c>.
    /// </summary>
    public static IQueryable<User> WithoutMutedFor(this IQueryable<User> users, Guid? viewerId) => users;

    /// <summary>The F28 seam for muted fields (see <see cref="WithoutMutedFor(IQueryable{User}, Guid?)"/>).</summary>
    public static IQueryable<Field> WithoutMutedFor(this IQueryable<Field> fields, Guid? viewerId) => fields;

    /// <summary>The F28 seam for muted topics (see <see cref="WithoutMutedFor(IQueryable{User}, Guid?)"/>).</summary>
    public static IQueryable<Topic> WithoutMutedFor(this IQueryable<Topic> topics, Guid? viewerId) => topics;
}
