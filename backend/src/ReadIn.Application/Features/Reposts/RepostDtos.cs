using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.Reposts;

/// <summary>PUT / DELETE /articles/{id}/repost (SPEC F29): counted from the rows right after the change.</summary>
public sealed record RepostStateDto(int RepostCount, bool IsReposted);

/// <summary>
/// The card's label "أعاد نشره {name}" / "{name} و{n} غيره أعادوا نشره" (SPEC F29, F34). On the Following feed:
/// <see cref="User"/> is the newest reposter the viewer follows and <see cref="OthersCount"/> the other followed
/// reposters; on a profile's Reposts tab: the profile's owner and 0. <see cref="RepostedAt"/> is that repost's time,
/// where the item is placed.
/// </summary>
public sealed record RepostLabelDto(AuthorDto User, int OthersCount, DateTime RepostedAt);
