using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Reading;
using ReadIn.Application.Features.Reading.Commands.RecordProgress;
using ReadIn.Application.Features.Reading.Queries.GetMyHeatmap;
using ReadIn.Application.Features.Reading.Queries.GetMyStats;

namespace ReadIn.Api.Endpoints;

/// <summary>Reading progress, the "read" rule (SPEC F04) and streaks and reading stats (SPEC F08, ADR 0013).</summary>
internal sealed class ReadingEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPut("/articles/{id:guid}/progress", async (Guid id, ReadingProgressRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RecordReadingProgressCommand(id, body.Language, body.Percent, body.LastPosition, body.ActiveSecondsDelta), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.ReadingProgress)
            .WithTags("Reading")
            .WithSummary("Report scroll percent, position and active seconds since the previous report; completes the article at ≥ 70% and ≥ 30 s")
            .Produces<ReadingProgressResultDto>();

        var stats = api.MapGroup("/me/stats").RequireAuthorization().WithTags("Reading");

        stats.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyReadingStatsQuery(), ct)).ToHttp(http))
            .WithSummary("The signed-in user's streak, freezes, totals, last 7/30 days and top fields")
            .Produces<ReadingStatsDto>();

        stats.MapGet("/heatmap", async (int? days, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyReadingHeatmapQuery(days ?? GetMyReadingHeatmapQuery.DefaultDays), ct)).ToHttp(http))
            .WithSummary("Days with a completed article or a streak freeze, for the reading heatmap (default the last 365 days)")
            .Produces<ReadingHeatmapDto>();
    }
}

/// <summary>Body of PUT /articles/{id}/progress.</summary>
internal sealed record ReadingProgressRequest(string Language, int Percent, string? LastPosition, int ActiveSecondsDelta);
