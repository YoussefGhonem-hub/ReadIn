using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Follows.Queries.GetFollowList;

public enum FollowList
{
    /// <summary>People who follow the user.</summary>
    Followers,

    /// <summary>People the user follows.</summary>
    Following,
}

/// <summary>
/// GET /users/{id}/followers and /users/{id}/following — newest first; <see cref="Search"/> matches the display name or
/// @username (SPEC F12).
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetFollowListQuery(Guid UserId, FollowList List, string? Search, string? Cursor, int Limit)
    : IQuery<Result<CursorPage<UserSummaryDto>>>;
