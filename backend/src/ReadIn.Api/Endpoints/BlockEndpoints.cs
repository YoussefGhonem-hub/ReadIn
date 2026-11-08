using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Blocks;

namespace ReadIn.Api.Endpoints;

/// <summary>F36 Block (SPEC §17.2 "Block"). Bearer only; writes need users.block and the writes limit.</summary>
internal sealed class BlockEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/users").RequireAuthorization().WithTags("Block");

        users.MapPut("/{id:guid}/block", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new BlockUserCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Block someone, both ways; ends the follows between you (idempotent; not yourself; at most 1,000)")
            .Produces<UserBlockStateDto>();

        users.MapDelete("/{id:guid}/block", async (Guid id, bool? restoreFollow, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnblockUserCommand(id, restoreFollow ?? false), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unblock (idempotent); restoreFollow=true follows them again (the toast's Undo)")
            .Produces<UserBlockStateDto>();

        api.MapGet("/me/blocked", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetBlockedUsersQuery(), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Block")
            .WithSummary("Settings → Blocked accounts: the people you blocked, newest first")
            .Produces<BlockedUsersDto>();
    }
}
