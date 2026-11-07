using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Content;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// The admin console's Content (SPEC F23): published and archived articles with their filters, the latest comments, and
/// featured articles. Lists need <c>moderation.manage</c>, featuring <c>articles.feature</c> (checked by the messages).
/// </summary>
internal sealed class AdminContentEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var admin = api.MapGroup("/admin").RequireAuthorization().WithTags("Admin");

        admin.MapGet("/articles", async (
                    string? from, string? to, string? field, string? topic, string? writer, string? status, string? hidden, string? featured,
                    string? reported, string? q, string? sort, int? page, int? pageSize, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminArticlesQuery(from, to, field, topic, writer, status, hidden, featured, reported, q, sort, page, pageSize), ct))
                .ToHttp(http))
            .WithSummary("Admins (moderation.manage): published and archived articles, newest first (sort=featured: most recently featured first); offset pages")
            .Produces<PagedList<AdminArticleRowDto>>();

        admin.MapGet("/articles/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminArticleQuery(id), ct)).ToHttp(http))
            .WithSummary("Admins (moderation.manage): one article's row (\"Open in console\")")
            .Produces<AdminArticleRowDto>();

        admin.MapGet("/comments", async (string? hidden, int? page, int? pageSize, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminCommentsQuery(hidden, page, pageSize), ct)).ToHttp(http))
            .WithSummary("Admins (moderation.manage): the latest comments and replies across all articles; offset pages")
            .Produces<PagedList<AdminCommentRowDto>>();

        admin.MapPut("/articles/{id:guid}/featured", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new FeatureArticleCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (articles.feature): feature an article readers can open on Explore; idempotent");

        admin.MapDelete("/articles/{id:guid}/featured", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnfeatureArticleCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (articles.feature): unfeature an article; idempotent");
    }
}
