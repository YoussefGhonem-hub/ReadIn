using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Comments;
using ReadIn.Application.Features.Comments.Commands;
using ReadIn.Application.Features.Comments.Queries;

namespace ReadIn.Api.Endpoints;

/// <summary>Comments and replies (SPEC F11) and @mention suggestions. Reports and moderation are in <see cref="ModerationEndpoints"/>.</summary>
internal sealed class CommentEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var articles = api.MapGroup("/articles").WithTags("Comments");

        articles.MapGet("/{id:guid}/comments", async (Guid id, string? sort, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetArticleCommentsQuery(id, ParseSort(sort), cursor, limit ?? 20), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("Top-level comments with their first replies; the pinned one first. sort=top (default) | new")
            .Produces<CommentPageDto>();

        articles.MapPost("/{id:guid}/comments", async (Guid id, CommentBody body, ISender sender, HttpContext http, CancellationToken ct) =>
                Created(await sender.Send(new PostCommentCommand(id, body.Body), ct), http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Comments)
            .WithSummary("Comment on an article (≤ 2000 characters; @username mentions are linked)")
            .Produces<CommentDto>(StatusCodes.Status201Created);

        var comments = api.MapGroup("/comments").WithTags("Comments");

        comments.MapGet("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetCommentQuery(id), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("One comment as the viewer sees it (refetched after a live event); deleted ones come back as placeholders")
            .Produces<CommentDto>();

        comments.MapGet("/{id:guid}/replies", async (Guid id, string? cursor, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetCommentRepliesQuery(id, cursor, limit ?? 20), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithSummary("A thread's replies, oldest first")
            .Produces<CursorPage<CommentDto>>();

        comments.MapPost("/{id:guid}/replies", async (Guid id, CommentBody body, ISender sender, HttpContext http, CancellationToken ct) =>
                Created(await sender.Send(new PostReplyCommand(id, body.Body), ct), http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Comments)
            .WithSummary("Reply to a comment; replying to a reply joins the same thread (one level of replies)")
            .Produces<CommentDto>(StatusCodes.Status201Created);

        comments.MapPatch("/{id:guid}", async (Guid id, CommentBody body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new EditCommentCommand(id, body.Body), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Edit an own comment (shows \"edited\")")
            .Produces<CommentDto>();

        comments.MapDelete("/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeleteCommentCommand(id), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete an own comment (soft; a thread with replies keeps a placeholder)");

        comments.MapPut("/{id:guid}/like", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetCommentLikeCommand(id, Liked: true), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Like a comment (idempotent)")
            .Produces<CommentLikeDto>();

        comments.MapDelete("/{id:guid}/like", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetCommentLikeCommand(id, Liked: false), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Remove a like (idempotent)")
            .Produces<CommentLikeDto>();

        comments.MapPost("/{id:guid}/pin", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetCommentPinCommand(id, Pinned: true), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("The article's author pins a top-level comment; the previously pinned one is unpinned")
            .Produces<CommentDto>();

        comments.MapDelete("/{id:guid}/pin", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetCommentPinCommand(id, Pinned: false), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unpin")
            .Produces<CommentDto>();

        api.MapGet("/users/mention-suggestions", async (string? q, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMentionSuggestionsQuery(q, limit ?? 8), ct)).ToHttp(http))
            .RequireAuthorization()
            .WithTags("Comments")
            .WithSummary("People to @mention while typing, by @username prefix or name")
            .Produces<IReadOnlyList<MentionCandidateDto>>();
    }

    private static CommentSort ParseSort(string? sort) =>
        string.Equals(sort, "new", StringComparison.OrdinalIgnoreCase) ? CommentSort.New : CommentSort.Top;

    private static IResult Created(Domain.Common.Result<CommentDto> result, HttpContext http) =>
        result.IsSuccess
            ? TypedResults.Created($"/api/v1/comments/{result.Value.Id}", result.Value)
            : result.Error!.ToProblem(http);
}

/// <summary>Body of POST /articles/{id}/comments, POST /comments/{id}/replies and PATCH /comments/{id}.</summary>
internal sealed record CommentBody(string? Body);
