using Mediator;
using ReadIn.Application.Features.MobileApp;
using ReadIn.Application.Features.MobileApp.Queries.GetUpdatePolicy;

namespace ReadIn.Api.Endpoints;

/// <summary>What the mobile app asks before anything else: whether this build must be updated first. Public.</summary>
internal sealed class MobileAppEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/app/update-policy", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                // Operators raise the minimum when an old build must stop: every answer is checked with the server first.
                http.Response.Headers.CacheControl = "no-cache";
                return TypedResults.Ok(await sender.Send(new GetUpdatePolicyQuery(), ct));
            })
            .AllowAnonymous()
            .WithTags("App")
            .WithSummary("The oldest iOS and Android app versions that may still run (null: no forced update) and their store pages")
            .Produces<UpdatePolicyDto>();
    }
}
