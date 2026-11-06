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
public sealed record RepostLabelDto(AuthorDto User, int OthersCount, DateTime RepostedAt, string? Caption);
