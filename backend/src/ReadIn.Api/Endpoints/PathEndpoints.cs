using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Application.Features.LearningPaths.Admin;
using ReadIn.Application.Features.LearningPaths.Commands.Enrollment;
using ReadIn.Application.Features.LearningPaths.Queries.GetArticlePath;
using ReadIn.Application.Features.LearningPaths.Queries.GetMyPaths;
using ReadIn.Application.Features.LearningPaths.Queries.GetPathBySlug;
using ReadIn.Application.Features.LearningPaths.Queries.GetPaths;
using ReadIn.Application.Features.Reading.Queries.GetContinueReading;

namespace ReadIn.Api.Endpoints;

/// <summary>F09 learning paths, the Home "continue reading" and path cards (F03) and the reader's "Next in path" block.</summary>
internal sealed class PathEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var paths = api.MapGroup("/paths").WithTags("Learning paths").AllowAnonymous();

        paths.MapGet("/", async (string? field, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetPathsQuery(field, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Published learning paths in editorial order; field = field slug. Signed in: your progress and enrollment")
            .Produces<IReadOnlyList<PathCardDto>>();

        paths.MapGet("/{slug}", async (string slug, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetPathBySlugQuery(slug, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("A learning path with its articles in order")
            .Produces<PathDetailsDto>();

        api.MapGet("/articles/{id:guid}/path", async (Guid id, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetArticlePathQuery(id, user.UiLanguage), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);
                return result.Value is null ? Results.NoContent() : TypedResults.Ok(result.Value);
            })
            .AllowAnonymous()
            .WithTags("Learning paths")
            .WithSummary("The article's learning path for the reader's \"Next in path\" block; 204 when it is in none")
            .Produces<ArticlePathDto>()
            .Produces(StatusCodes.Status204NoContent);

        api.MapGet("/users/{username}/paths", async (string username, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetProfilePathsQuery(username, user.UiLanguage), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithTags("Profile")
            .WithSummary("The paths a user is enrolled in, with their progress; same privacy rule as their reading stats")
            .Produces<IReadOnlyList<PathCardDto>>();

        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Learning paths");

        me.MapGet("/paths", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyPathsQuery(user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Your enrolled paths: in progress first (latest activity first), then completed")
            .Produces<IReadOnlyList<PathCardDto>>();

        me.MapGet("/paths/active", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetActivePathQuery(user.UiLanguage), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);
                return result.Value is null ? Results.NoContent() : TypedResults.Ok(result.Value);
            })
            .WithSummary("The Home learning-path card: your enrolled path in progress with the latest activity; 204 when none")
            .Produces<PathCardDto>()
            .Produces(StatusCodes.Status204NoContent);

        me.MapPut("/paths/{pathId:guid}", async (Guid pathId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new EnrollInPathCommand(pathId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Enroll in a learning path (idempotent)")
            .Produces<PathCardDto>();

        me.MapDelete("/paths/{pathId:guid}", async (Guid pathId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new LeavePathCommand(pathId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Leave a learning path (idempotent); your reading history stays");

        me.MapGet("/continue-reading", async (int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetContinueReadingQuery(limit ?? GetContinueReadingQuery.DefaultLimit, user.UiLanguage), ct)).ToHttp(http))
            .WithTags("Reading")
            .WithSummary("Unfinished articles (≥ 5%, last 30 days), most recently read first; limit 1–10, default 3")
            .Produces<IReadOnlyList<ContinueReadingDto>>();

        var admin = api.MapGroup("/admin/paths").RequireAuthorization().WithTags("Admin");

        admin.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminPathsQuery(), ct)).ToHttp(http))
            .WithSummary("Every learning path, unpublished included (paths.manage)")
            .Produces<IReadOnlyList<AdminPathDto>>();

        admin.MapPost("/", async (UpsertPathRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreatePathCommand(body), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/paths/{result.Value.Slug}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Create a learning path (paths.manage)")
            .Produces<CreatedPath>(StatusCodes.Status201Created);

        admin.MapPut("/{id:guid}", async (Guid id, UpsertPathRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UpdatePathCommand(id, body), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Edit or (un)publish a learning path; editorial paths are read-only (paths.manage)");

        admin.MapPut("/{id:guid}/items", async (Guid id, SetPathItemsRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetPathItemsCommand(id, body.ArticleIds ?? []), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Replace a path's articles, in order: 1–100 different published articles (paths.manage)");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeletePathCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete a learning path and its enrollments (paths.manage)");

        // F23: beside PUT /{id:guid}; the guid constraint keeps them apart.
        admin.MapPut("/featured", async (SetFeaturedPathsRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetFeaturedPathsCommand(body.PathIds), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("The whole featured list in Explore order: 0–20 different paths, editorial ones too; [] unfeatures all (articles.feature)");
    }
}

/// <summary>Body of PUT /admin/paths/{id}/items.</summary>
internal sealed record SetPathItemsRequest(IReadOnlyList<Guid>? ArticleIds);

/// <summary>Body of PUT /admin/paths/featured (SPEC F23).</summary>
internal sealed record SetFeaturedPathsRequest(IReadOnlyList<Guid>? PathIds);
