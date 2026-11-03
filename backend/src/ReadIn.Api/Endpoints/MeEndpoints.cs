using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Users;
using ReadIn.Application.Features.Users.Commands.RegisterDevice;
using ReadIn.Application.Features.Users.Commands.SyncUser;
using ReadIn.Application.Features.Users.Commands.UpdateInterests;
using ReadIn.Application.Features.Users.Commands.UpdatePreferences;
using ReadIn.Application.Features.Users.Commands.UpdateProfile;
using ReadIn.Application.Features.Users.Queries.GetMe;

namespace ReadIn.Api.Endpoints;

internal sealed class AuthEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/auth/sync", async (SyncUserCommand? body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body ?? new SyncUserCommand(null, null), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Auth)
            .WithTags("Auth")
            .WithSummary("Create or refresh the ReadIn user for the signed-in Firebase account")
            .Produces<MeDto>();
    }
}

internal sealed class MeEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Me");

        me.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMeQuery(), ct)).ToHttp(http))
            .WithSummary("The signed-in user's profile, preferences, roles and permissions")
            .Produces<MeDto>();

        me.MapPatch("/", async (UpdateProfileCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Update profile (name, @username, bio, avatar, links)");

        me.MapPut("/preferences", async (UpdatePreferencesCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Update UI/article language, theme, time zone and reminder time");

        me.MapPut("/interests", async (UpdateInterestsCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Replace followed fields/topics (at least 3)");

        me.MapPost("/devices", async (RegisterDeviceCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .WithSummary("Register an FCM device token for push notifications");
    }
}
