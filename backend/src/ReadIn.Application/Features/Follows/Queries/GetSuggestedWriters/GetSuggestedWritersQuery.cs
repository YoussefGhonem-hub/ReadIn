using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Queries.GetSuggestedWriters;

/// <summary>
/// GET /users/suggested — writers to follow (SPEC F12): they have published articles in fields that overlap your
/// interests (a followed topic counts for its field), you don't follow them yet, and they are not you. Verified writers
/// first, then by follower count. When no writer overlaps your interests yet, any writer with published articles is
/// suggested, like the For you feed falls back to everything.
/// </summary>
[Authenticated]
public sealed record GetSuggestedWritersQuery(int Limit) : IQuery<Result<IReadOnlyList<UserSummaryDto>>>;
