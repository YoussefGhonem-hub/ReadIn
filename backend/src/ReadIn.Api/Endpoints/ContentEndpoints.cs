using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Commands.CreateArticle;
using ReadIn.Application.Features.Articles.Commands.DeleteArticle;
using ReadIn.Application.Features.Articles.Commands.PublishArticle;
using ReadIn.Application.Features.Articles.Commands.SetArticleAttachments;
using ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;
using ReadIn.Application.Features.Feed.Queries.GetForYouFeed;
using ReadIn.Application.Features.Feed.Queries.GetTodayArticle;
using ReadIn.Application.Features.Taxonomy;
using ReadIn.Application.Features.Taxonomy.Queries.GetFields;
using ReadIn.Application.Features.Taxonomy.Queries.GetTopicsByField;

namespace ReadIn.Api.Endpoints;

internal sealed class TaxonomyEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var fields = api.MapGroup("/fields").WithTags("Taxonomy").AllowAnonymous();

        fields.MapGet("/", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFieldsQuery(user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Enabled fields in display order")
            .Produces<IReadOnlyList<FieldDto>>();

        fields.MapGet("/{slug}/topics", async (string slug, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetTopicsByFieldQuery(slug, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Topics of a field")
            .Produces<IReadOnlyList<TopicDto>>();
    }
}

internal sealed class ArticleEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var articles = api.MapGroup("/articles").WithTags("Articles");

        articles.MapGet("/{slug}", async (string slug, string? lang, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleBySlugQuery(slug, lang, user.UiLanguage), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("A published article; ?lang=ar-EG|en picks the version (falls back to the source language)")
            .Produces<ArticleDetailsDto>();

        articles.MapPost("/", async (CreateArticleCommand body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(body, ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/articles/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Create a draft with its first language version (RDoc content); returns { id, slug }")
            .Produces<CreatedArticle>(StatusCodes.Status201Created);

        articles.MapPut("/{id:guid}/attachments", async (Guid id, SetAttachmentsRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetArticleAttachmentsCommand(id, body.Items ?? []), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Replace the attachments: 1–10 images (alt text required) or one PDF; [] removes them (ADR 0011)");

        articles.MapDelete("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteArticleCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete an own article; its attachments are deleted with their files");

        articles.MapPost("/{id:guid}/publish", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new PublishArticleCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Publish an own article now");
    }
}

/// <summary>Body of PUT /articles/{id}/attachments.</summary>
internal sealed record SetAttachmentsRequest(IReadOnlyList<AttachmentItemInput>? Items);

internal sealed class FeedEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var feed = api.MapGroup("/feed").WithTags("Feed").AllowAnonymous();

        feed.MapGet("/for-you", async (string? field, string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetForYouFeedQuery(field, cursor, limit ?? 20, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Personalised feed (interests first); guests get the latest articles")
            .Produces<CursorPage<ArticleCardDto>>();

        feed.MapGet("/today", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetTodayArticleQuery(user.UiLanguage), ct);
                if (result.IsFailure) return result.Error!.ToProblem(http);
                return result.Value is null ? Results.NoContent() : TypedResults.Ok(result.Value);
            })
            .WithSummary("Today's article (مقال النهارده); 204 when none is available yet")
            .Produces<ArticleCardDto>()
            .Produces(StatusCodes.Status204NoContent);
    }
}
