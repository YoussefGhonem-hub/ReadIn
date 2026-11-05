using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.WriterCategories;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F31 writer categories (SPEC §17.2, <c>docs/api/contract-v1.md</c> "Writer categories"): a profile's Categories tab and
/// category pages (guests too), the writer's own list and its writes, and an article's category.
/// </summary>
internal sealed class WriterCategoryEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/users").AllowAnonymous().WithTags("Writer categories");

        users.MapGet("/{username}/categories", async (string username, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetWriterCategoriesQuery(username), ct)).ToHttp(http))
            .WithSummary("The profile's Categories tab: categories with articles readers can see, in the writer's order, and the uncategorized count")
            .Produces<WriterCategoryListDto>();

        users.MapGet("/{username}/categories/{slug}", async (string username, string slug, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetWriterCategoryQuery(username, slug), ct)).ToHttp(http))
            .WithSummary("A category page's header; the slug _other is the writer's articles without a category")
            .Produces<WriterCategoryPageDto>();

        users.MapGet("/{username}/categories/{slug}/articles", async (string username, string slug, string? cursor, int? limit, ISender sender,
                ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetWriterCategoryArticlesQuery(username, slug, cursor, limit ?? WriterCategoryLimits.DefaultLimit, user.UiLanguage), ct))
                .ToHttp(http))
            .WithSummary("A category's articles readers can see, newest first, as post cards")
            .Produces<CursorPage<ArticleCardDto>>();

        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Writer categories");

        me.MapGet("/categories", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMyCategoriesQuery(), ct)).ToHttp(http))
            .WithSummary("All your categories in your order, empty ones included, and your uncategorized count")
            .Produces<WriterCategoryListDto>();

        me.MapPost("/categories", async (CategoryNameRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreateWriterCategoryCommand(body.Name), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/me/categories/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Create a category, added last (name 1–40 characters, unique per writer ignoring case and letter forms, at most 50)")
            .Produces<WriterCategoryDto>(StatusCodes.Status201Created);

        me.MapPatch("/categories/{id:guid}", async (Guid id, CategoryNameRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RenameWriterCategoryCommand(id, body.Name), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Rename a category; its slug (and so its links) stays")
            .Produces<WriterCategoryDto>();

        me.MapDelete("/categories/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteWriterCategoryCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete a category; its articles stay published, without a category");

        me.MapPut("/categories/order", async (CategoryOrderRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ReorderWriterCategoriesCommand(body.CategoryIds), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Reorder your categories; unknown ids are ignored and the ones left out keep their order after the listed ones")
            .Produces<WriterCategoryListDto>();

        api.MapPut("/articles/{id:guid}/category", async (Guid id, ArticleCategoryRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetArticleCategoryCommand(id, body.CategoryId), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Writer categories")
            .WithSummary("Put your article in one of your categories, or in none (null); at once, without a publish or a revision");
    }
}

/// <summary>Body of POST /me/categories and PATCH /me/categories/{id}.</summary>
internal sealed record CategoryNameRequest(string? Name);

/// <summary>Body of PUT /me/categories/order.</summary>
internal sealed record CategoryOrderRequest(IReadOnlyList<Guid>? CategoryIds);

/// <summary>Body of PUT /articles/{id}/category.</summary>
internal sealed record ArticleCategoryRequest(Guid? CategoryId);
