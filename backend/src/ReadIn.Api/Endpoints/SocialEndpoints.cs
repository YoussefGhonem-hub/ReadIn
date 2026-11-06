using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Realtime;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Feed.Queries.GetFollowingFeed;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.Follows.Commands.FollowInterest;
using ReadIn.Application.Features.Follows.Commands.FollowUser;
using ReadIn.Application.Features.Follows.Commands.UnfollowInterest;
using ReadIn.Application.Features.Follows.Commands.UnfollowUser;
using ReadIn.Application.Features.Follows.Queries.GetFollowList;
using ReadIn.Application.Features.Follows.Queries.GetSuggestedWriters;
using ReadIn.Application.Features.Reactions;
using ReadIn.Application.Features.Reactions.Commands.RemoveReaction;
using ReadIn.Application.Features.Reactions.Commands.SetReaction;
using ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;
using ReadIn.Application.Features.Reposts;
using ReadIn.Application.Features.SavedArticles;
using ReadIn.Application.Features.SavedArticles.Commands.AddToCollection;
using ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;
using ReadIn.Application.Features.SavedArticles.Commands.DeleteCollection;
using ReadIn.Application.Features.SavedArticles.Commands.RemoveFromCollection;
using ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;
using ReadIn.Application.Features.SavedArticles.Commands.SaveArticle;
using ReadIn.Application.Features.SavedArticles.Commands.UnsaveArticle;
using ReadIn.Application.Features.SavedArticles.Queries.GetCollections;
using ReadIn.Application.Features.SavedArticles.Queries.GetSavedArticles;
using ReadIn.Application.Features.Users;

namespace ReadIn.Api.Endpoints;

/// <summary>F10 Reactions (SPEC §17.2): one reaction per user per article, and "who reacted".</summary>
internal sealed class ReactionEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var articles = api.MapGroup("/articles").WithTags("Reactions");

        articles.MapPut("/{id:guid}/reaction", async (Guid id, SetReactionRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetReactionCommand(id, body?.Type), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Set or change your reaction: insightful | love | fire | mindBlown (reactions.create)")
            .Produces<ArticleReactionsDto>();

        articles.MapDelete("/{id:guid}/reaction", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RemoveReactionCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Remove your reaction (idempotent)")
            .Produces<ArticleReactionsDto>();

        articles.MapGet("/{id:guid}/reactions", async (Guid id, string? type, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleReactorsQuery(id, type, cursor, limit ?? 20), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("Who reacted, newest first; ?type= keeps one reaction")
            .Produces<CursorPage<ReactorDto>>();
    }
}

/// <summary>F29 Reposts (SPEC §17.2): repost an article to your followers, or undo it; both idempotent.</summary>
internal sealed class RepostEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var articles = api.MapGroup("/articles").WithTags("Reposts");

        articles.MapPut("/{id:guid}/repost", async (Guid id, RepostRequest? body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RepostArticleCommand(id, body?.Caption), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Repost an article, optionally with your thoughts, or set the caption of your repost (reposts.create); "
                + "400 repost.own_article on your own")
            .Produces<RepostStateDto>();

        articles.MapGet("/{id:guid}/repost", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetRepostStateQuery(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithSummary("Your repost of an article now, with its caption")
            .Produces<RepostStateDto>();

        articles.MapDelete("/{id:guid}/repost", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UndoRepostCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Undo your repost and its caption (idempotent)")
            .Produces<RepostStateDto>();
    }
}

/// <summary>Body of PUT /articles/{id}/reaction. A string, so an unknown reaction is the validation code reaction.invalid.</summary>
internal sealed record SetReactionRequest(string? Type);

/// <summary>
/// Optional body of PUT /articles/{id}/repost. A missing or null caption: none on a new repost, unchanged on an existing
/// one; a string sets it, and an empty one clears it.
/// </summary>
internal sealed record RepostRequest(string? Caption);

/// <summary>F13 Saved articles and collections (SPEC §17.2).</summary>
internal sealed class SavedEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Saved");

        me.MapPut("/saved/{articleId:guid}", async (Guid articleId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SaveArticleCommand(articleId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Save an article (idempotent)")
            .Produces<SaveStateDto>();

        me.MapDelete("/saved/{articleId:guid}", async (Guid articleId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnsaveArticleCommand(articleId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unsave an article and remove it from every collection (idempotent)")
            .Produces<SaveStateDto>();

        me.MapGet("/saved", async (string? field, string? q, Guid? collection, string? cursor, int? limit,
                ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetSavedArticlesQuery(field, q, collection, cursor, limit ?? 20, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Saved articles, newest saved first; field = field slug, q = title search, collection = collection id")
            .Produces<CursorPage<SavedArticleDto>>();

        me.MapGet("/collections", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetCollectionsQuery(), ct)).ToHttp(http))
            .WithSummary("Your collections, in name order")
            .Produces<IReadOnlyList<CollectionDto>>();

        me.MapPost("/collections", async (CollectionRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreateCollectionCommand(body.Name ?? string.Empty), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/me/collections/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Create a collection (name 1–60 characters, unique per user ignoring case, at most 50)")
            .Produces<CollectionDto>(StatusCodes.Status201Created);

        me.MapPatch("/collections/{id:guid}", async (Guid id, CollectionRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RenameCollectionCommand(id, body.Name ?? string.Empty), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Rename a collection")
            .Produces<CollectionDto>();

        me.MapDelete("/collections/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteCollectionCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete a collection; its articles stay saved");

        me.MapPut("/collections/{id:guid}/articles/{articleId:guid}", async (Guid id, Guid articleId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new AddToCollectionCommand(id, articleId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Add an article to a collection, saving it first if needed");

        me.MapDelete("/collections/{id:guid}/articles/{articleId:guid}", async (Guid id, Guid articleId, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RemoveFromCollectionCommand(id, articleId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Remove an article from a collection; it stays saved");
    }
}

/// <summary>Body of POST /me/collections and PATCH /me/collections/{id}.</summary>
internal sealed record CollectionRequest(string? Name);

/// <summary>F12 Follow (SPEC §17.2): writers, followers/following lists, suggestions, and fields/topics as interests.</summary>
internal sealed class FollowEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/users").WithTags("Follow");

        users.MapPut("/{id:guid}/follow", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new FollowUserCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Follow a writer (idempotent; follows.manage)")
            .Produces<FollowStateDto>();

        users.MapDelete("/{id:guid}/follow", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnfollowUserCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unfollow a writer (idempotent)")
            .Produces<FollowStateDto>();

        users.MapGet("/{id:guid}/followers", async (Guid id, string? q, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFollowListQuery(id, FollowList.Followers, q, cursor, limit ?? 20), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("Followers, newest first; q matches the display name or @username")
            .Produces<CursorPage<UserSummaryDto>>();

        users.MapGet("/{id:guid}/following", async (Guid id, string? q, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFollowListQuery(id, FollowList.Following, q, cursor, limit ?? 20), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("Followed users, newest first; q matches the display name or @username")
            .Produces<CursorPage<UserSummaryDto>>();

        users.MapGet("/suggested", async (int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetSuggestedWritersQuery(limit ?? 10), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithSummary("Writers to follow by field overlap with your interests: verified first, then by followers")
            .Produces<IReadOnlyList<UserSummaryDto>>();

        api.MapGet("/feed/following", async (string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFollowingFeedQuery(cursor, limit ?? 20, user.UiLanguage), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Feed")
            .WithSummary("The Following tab: published articles by the writers you follow, newest first")
            .Produces<CursorPage<ArticleCardDto>>();

        var interests = api.MapGroup("/me/interests").RequireAuthorization().WithTags("Follow");

        interests.MapPut("/fields/{fieldId:guid}", (Guid fieldId, ISender sender, HttpContext http, CancellationToken ct) =>
                FollowAsync(new FollowInterestCommand(InterestTarget.Field, fieldId), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Follow a field (an interest; idempotent)")
            .Produces<InterestsDto>();

        interests.MapDelete("/fields/{fieldId:guid}", (Guid fieldId, ISender sender, HttpContext http, CancellationToken ct) =>
                UnfollowAsync(new UnfollowInterestCommand(InterestTarget.Field, fieldId), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unfollow a field; refused when fewer than 3 interests would remain")
            .Produces<InterestsDto>();

        interests.MapPut("/topics/{topicId:guid}", (Guid topicId, ISender sender, HttpContext http, CancellationToken ct) =>
                FollowAsync(new FollowInterestCommand(InterestTarget.Topic, topicId), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Follow a topic (an interest; idempotent)")
            .Produces<InterestsDto>();

        interests.MapDelete("/topics/{topicId:guid}", (Guid topicId, ISender sender, HttpContext http, CancellationToken ct) =>
                UnfollowAsync(new UnfollowInterestCommand(InterestTarget.Topic, topicId), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unfollow a topic; refused when fewer than 3 interests would remain")
            .Produces<InterestsDto>();
    }

    private static async Task<IResult> FollowAsync(FollowInterestCommand command, ISender sender, HttpContext http, CancellationToken ct) =>
        (await sender.Send(command, ct)).ToHttp(http);

    private static async Task<IResult> UnfollowAsync(UnfollowInterestCommand command, ISender sender, HttpContext http, CancellationToken ct) =>
        (await sender.Send(command, ct)).ToHttp(http);
}

/// <summary>Real-time maintenance (SPEC §21.2), SuperAdmin only.</summary>
internal sealed class AdminCounterEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapPost("/admin/realtime/rebuild-counters", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RebuildArticleCountersCommand(), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Admin")
            .WithSummary("Recompute every article's reaction and save counters from SQL and republish them (system.settings)")
            .Produces<CountersRebuiltDto>();
    }
}
