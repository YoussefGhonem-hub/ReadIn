using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Profiles;
using ReadIn.Application.Features.Profiles.Queries.GetProfile;
using ReadIn.Application.Features.Profiles.Queries.GetProfileArticles;
using ReadIn.Application.Features.Profiles.Queries.GetProfileReadingStats;
using ReadIn.Application.Features.Reading;
using ReadIn.Application.Features.Reading.Queries.GetMyHeatmap;
using ReadIn.Application.Features.Users.Commands.UpdatePrivacy;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F14 Profile (SPEC §17.2): the public profile, its Articles tab and its reading stats, plus Settings → Privacy (F18).
/// <c>{username}</c> never clashes with <c>/users/suggested</c> or <c>/users/username-available</c>: literal segments win.
/// </summary>
internal sealed class ProfileEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/users").AllowAnonymous().WithTags("Profile");

        users.MapGet("/{username}", async (string username, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetProfileQuery(username), ct)).ToHttp(http))
            .WithSummary("Public profile by @username (ignoring case and a leading @): header, links, expertise, stats, follow state")
            .Produces<ProfileDto>();

        users.MapGet("/{username}/articles", async (string username, string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetProfileArticlesQuery(username, cursor, limit ?? 20, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("The profile's published articles, newest first")
            .Produces<CursorPage<ArticleCardDto>>();

        users.MapGet("/{username}/stats", async (string username, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetProfileReadingStatsQuery(username), ct)).ToHttp(http))
            .WithSummary("The profile's reading stats in that user's time zone; 403 profile.stats_private unless public or your own")
            .Produces<ReadingStatsDto>();

        users.MapGet("/{username}/stats/heatmap", async (string username, int? days, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetProfileReadingHeatmapQuery(username, days ?? GetMyReadingHeatmapQuery.DefaultDays), ct)).ToHttp(http))
            .WithSummary("The profile's reading heatmap (default the last 365 days); same privacy rule as /stats")
            .Produces<ReadingHeatmapDto>();

        api.MapPut("/me/privacy", async (UpdatePrivacyCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(body, ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Me")
            .WithSummary("Settings → Privacy: show the reading stats on your public profile, and who can @mention you (each optional)");
    }
}
