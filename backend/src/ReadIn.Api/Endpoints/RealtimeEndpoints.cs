using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Realtime.Commands.CreateRealtimeToken;

namespace ReadIn.Api.Endpoints;

/// <summary>Live updates through the Firebase Realtime Database (SPEC §21.2, F27, ADR 0008).</summary>
internal sealed class RealtimeEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/realtime/token", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new CreateRealtimeTokenCommand(), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.RealtimeToken)
            .WithTags("Realtime")
            .WithSummary("Firebase custom token (uid = your user id) that only lets you read /live/users/{id}; not a sign-in")
            .Produces<RealtimeTokenDto>();
    }
}
