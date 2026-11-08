using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Follows.Commands.FollowUser;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Blocks;

/// <param name="FollowRemoved">PUT: you followed them and that follow ended (the toast's Undo can follow again).</param>
public sealed record UserBlockStateDto(Guid UserId, bool IsBlocked, bool FollowRemoved);

public sealed record BlockedUserSummaryDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified);

public sealed record BlockedUserDto(BlockedUserSummaryDto User, DateTime BlockedAt);

public sealed record BlockedUsersDto(IReadOnlyList<BlockedUserDto> Items);

/// <summary>
/// PUT /users/{id}/block (SPEC F36): blocks the user, both ways from then on, and ends the follows between you. Idempotent.
/// Not yourself; at most 1,000 blocks. The blocked person isn't told.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Blocks.Manage)]
public sealed record BlockUserCommand(Guid UserId) : ICommand<Result<UserBlockStateDto>>;

/// <summary>
/// DELETE /users/{id}/block (SPEC F36): unblocks (idempotent). <paramref name="RestoreFollow"/> follows them again (the
/// toast's Undo); their follow of you never comes back.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Blocks.Manage)]
public sealed record UnblockUserCommand(Guid UserId, bool RestoreFollow) : ICommand<Result<UserBlockStateDto>>;

/// <summary>GET /me/blocked (SPEC F36, F18): Settings → Blocked accounts, newest block first, not paged (≤ 1,000).</summary>
[Authenticated]
public sealed record GetBlockedUsersQuery : IQuery<Result<BlockedUsersDto>>;

internal sealed class BlockUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, BlockRelations blocks, TimeProvider clock)
    : ICommandHandler<BlockUserCommand, Result<UserBlockStateDto>>
{
    public async ValueTask<Result<UserBlockStateDto>> Handle(BlockUserCommand command, CancellationToken cancellationToken)
    {
        var blockerId = currentUser.RequireUserId();
        var userId = command.UserId;
        if (userId == blockerId) return BlockErrors.Self;
        if (!await db.Users.AnyAsync(u => u.Id == userId, cancellationToken)) return UserErrors.NotFound;

        // Under the blocker's row lock, so the 1,000 limit holds for concurrent blocks and a repeat never races the index.
        var outcome = await db.LockedForUserAsync<Result<bool>>(blockerId, async ct =>
        {
            var blocked = await blocks.BlockAsync(blockerId, userId, clock.GetUtcNow().UtcDateTime, ct);
            if (blocked.IsFailure) return blocked.Error;
            await db.SaveChangesAsync(ct);
            return blocked.Value;
        }, cancellationToken);
        if (outcome.IsFailure) return outcome.Error;

        return new UserBlockStateDto(userId, IsBlocked: true, FollowRemoved: outcome.Value);
    }
}

internal sealed class UnblockUserCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<UnblockUserCommand, Result<UserBlockStateDto>>
{
    public async ValueTask<Result<UserBlockStateDto>> Handle(UnblockUserCommand command, CancellationToken cancellationToken)
    {
        var blockerId = currentUser.RequireUserId();
        var userId = command.UserId;
        if (!await db.Users.AnyAsync(u => u.Id == userId, cancellationToken)) return UserErrors.NotFound;

        await db.UserBlocks.Where(b => b.BlockerId == blockerId && b.BlockedId == userId).ExecuteDeleteAsync(cancellationToken);

        // The toast's Undo: follow again, as PUT /users/{id}/follow would. Still blocked by them, or anything else that
        // refuses the follow, is ignored: the unblock itself happened.
        if (command.RestoreFollow && userId != blockerId &&
            !await db.UserBlocks.AnyAsync(b => b.BlockerId == userId && b.BlockedId == blockerId, cancellationToken))
        {
            await FollowUserCommandHandler.FollowAsync(db, blockerId, userId, clock.GetUtcNow().UtcDateTime, cancellationToken);
        }

        return new UserBlockStateDto(userId, IsBlocked: false, FollowRemoved: false);
    }
}

internal sealed class GetBlockedUsersQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage)
    : IQueryHandler<GetBlockedUsersQuery, Result<BlockedUsersDto>>
{
    public async ValueTask<Result<BlockedUsersDto>> Handle(GetBlockedUsersQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var rows = await db.UserBlocks.AsNoTracking()
            .Where(b => b.BlockerId == userId)
            .Join(db.Users, b => b.BlockedId, u => u.Id, (b, u) => new { b.CreatedAt, u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.IsVerified })
            .OrderByDescending(r => r.CreatedAt)
            .ThenBy(r => r.Id)
            .ToListAsync(cancellationToken);
        return new BlockedUsersDto([.. rows.Select(r => new BlockedUserDto(
            new BlockedUserSummaryDto(r.Id, r.DisplayName, r.Username, storage.ToPublicUrl(r.AvatarUrl), r.IsVerified), r.CreatedAt))]);
    }
}
