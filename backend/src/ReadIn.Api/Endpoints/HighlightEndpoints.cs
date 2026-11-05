using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Highlights;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F30 Highlights (SPEC §17.2): the reader's marks for one version (guests too), highlighting and removing (Bearer,
/// highlights.create, the writes limit), and your highlights for the Saved tab.
/// </summary>
internal sealed class HighlightEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var articles = api.MapGroup("/articles").WithTags("Highlights");

        articles.MapGet("/{id:guid}/highlights", async (Guid id, string? lang, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleHighlightsQuery(id, lang), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("Your highlights on the version (lang, else the source language) and its popular ranges (≥ 3 readers, at most 5)")
            .Produces<ArticleHighlightsDto>();

        articles.MapPost("/{id:guid}/highlights", async (Guid id, CreateHighlightRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(
                    new CreateHighlightCommand(id, body?.Language, body?.BlockId, body?.StartOffset, body?.EndOffset, body?.Text), ct);
                if (result.IsFailure) return result.Error.ToProblem(http);
                return result.Value.Created
                    ? TypedResults.Created($"/api/v1/articles/{id}/highlights", result.Value.Result)
                    : TypedResults.Ok(result.Value.Result);
            })
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Highlight a range of one block (highlights.create); joins your highlights it overlaps or touches")
            .Produces<HighlightCreatedDto>(StatusCodes.Status201Created)
            .Produces<HighlightCreatedDto>();

        api.MapDelete("/highlights/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteHighlightCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Highlights")
            .WithSummary("Remove one of your highlights; 404 highlight.not_found for anything else");

        api.MapGet("/me/highlights", async (string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyHighlightsQuery(cursor, limit ?? 20), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Highlights")
            .WithSummary("Saved → Highlights: your highlights grouped by article version, newest first")
            .Produces<CursorPage<HighlightGroupDto>>();
    }
}

/// <summary>Body of POST /articles/{id}/highlights. Nullable, so a missing member is the validation code validation.required.</summary>
internal sealed record CreateHighlightRequest(string? Language, string? BlockId, int? StartOffset, int? EndOffset, string? Text);
