using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Commands.DeleteArticle;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;
using ReadIn.Application.Features.Articles.Queries.GetArticlePreview;
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

        api.MapGet("/tags", async (string? q, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SearchTagsQuery(q, limit ?? 10), ct)).ToHttp(http))
            .WithTags("Taxonomy")
            .AllowAnonymous()
            .WithSummary("Tag suggestions for the editor: names or slugs starting with q, most used first (F05)")
            .Produces<IReadOnlyList<TagDto>>();
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

        articles.MapGet("/{id:guid}/preview", async (Guid id, string? lang, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticlePreviewQuery(id, lang), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("A feed card's \"Read more\" (F34): the first whole blocks, about 300 words, as RDoc; isComplete when that is the whole article")
            .Produces<ArticlePreviewDto>();

        // F05 editor (ADR 0015): a private working copy per article, published as a whole.
        articles.MapPost("/", async (ArticleDraftDocument body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreateArticleDraftCommand(body), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/articles/{result.Value.Id}/edit", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Create a never-published draft from an editor document (unfinished is fine)")
            .Produces<ArticleEditDto>(StatusCodes.Status201Created);

        articles.MapGet("/{id:guid}/edit", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleForEditQuery(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithSummary("The working copy of an own article with its live checks")
            .Produces<ArticleEditDto>();

        articles.MapPut("/{id:guid}/draft", async (Guid id, SaveDraftRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SaveArticleDraftCommand(id, body.BaseVersion, body.Document!), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Autosave: replace the working copy; 409 article.draft_conflict when baseVersion is stale")
            .Produces<ArticleEditDto>();

        articles.MapDelete("/{id:guid}/draft", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DiscardArticleDraftCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Discard the unpublished changes of a published article")
            .Produces<ArticleEditDto>();

        articles.MapPost("/{id:guid}/publish", async (Guid id, BaseVersionRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new PublishArticleDraftCommand(id, body.BaseVersion), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Publish the working copy (first publish or Update); 400 lists the problems")
            .Produces<PublishedArticleDto>();

        articles.MapGet("/{id:guid}/revisions", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleRevisionsQuery(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithSummary("Revision history of an own article, newest first")
            .Produces<IReadOnlyList<ArticleRevisionDto>>();

        articles.MapGet("/{id:guid}/revisions/{number:int}", async (Guid id, int number, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleRevisionQuery(id, number), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithSummary("One revision's document, for its preview")
            .Produces<ArticleRevisionDetailsDto>();

        articles.MapPost("/{id:guid}/revisions/{number:int}/restore", async (Guid id, int number, BaseVersionRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RestoreArticleRevisionCommand(id, number, body.BaseVersion), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Copy a revision into the working copy (live after the next publish)")
            .Produces<ArticleEditDto>();

        articles.MapDelete("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteArticleCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete an own article; its attachments are deleted with their files");

        api.MapGroup("/me").RequireAuthorization().WithTags("Articles")
            .MapGet("/articles", async (string? status, string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyArticlesQuery(status, cursor, limit ?? 20, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("My articles: ?status=draft (never published) or published")
            .Produces<CursorPage<MyArticleDto>>();
    }
}

/// <summary>Body of PUT /articles/{id}/draft.</summary>
internal sealed record SaveDraftRequest(int BaseVersion, ArticleDraftDocument? Document);

/// <summary>Body of publish and restore: the working-copy version the editor last saw.</summary>
internal sealed record BaseVersionRequest(int BaseVersion);

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
