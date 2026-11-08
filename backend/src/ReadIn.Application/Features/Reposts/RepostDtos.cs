using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.Reposts;

/// <summary>
/// GET / PUT / DELETE /articles/{id}/repost (SPEC F29): counted from the rows right after the change. <see cref="Caption"/>
/// is your repost's caption: null when it has none or you haven't reposted.
/// </summary>
public sealed record RepostStateDto(int RepostCount, bool IsReposted, string? Caption);

/// <summary>
/// The card's label "أعاد نشره {name}" / "{name} و{n} غيره أعادوا نشره" (SPEC F29, F34). On the Following feed:
/// <see cref="User"/> is the newest reposter the viewer follows and <see cref="OthersCount"/> the other followed
/// reposters; on a profile's Reposts tab: the profile's owner and 0. <see cref="RepostedAt"/> is that repost's time,
/// where the item is placed, and <see cref="Caption"/> that repost's caption (plain text, shown under the label).
/// </summary>
public sealed record RepostLabelDto(AuthorDto User, int OthersCount, DateTime RepostedAt, string? Caption)
{
    /// <summary>The labelled repost, for its "⋯" Report (SPEC F22: a repost is a report target).</summary>
    public Guid RepostId { get; init; }

    /// <summary>The viewer reported this repost (SPEC F22): clients collapse its caption for them, with "Show".</summary>
    public bool ReportedByMe { get; init; }
}

/// <summary>The viewer's reports of reposts (SPEC F22), for <see cref="RepostLabelDto.ReportedByMe"/>.</summary>
internal static class RepostLabels
{
    public static async Task<HashSet<Guid>> ReportedByAsync(
        Common.Interfaces.IAppDbContext db, Guid? viewerId, IReadOnlyCollection<Guid> repostIds, CancellationToken ct)
    {
        if (viewerId is not { } viewer || repostIds.Count == 0) return [];
        return [.. await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(
            db.Reports.Where(r => r.ReporterId == viewer && r.TargetType == Domain.Moderation.ReportTargetType.Repost && repostIds.Contains(r.TargetId))
                .Select(r => r.TargetId), ct)];
    }
}
