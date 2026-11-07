using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Admin.Tags;
using ReadIn.Application.Features.Admin.Taxonomy;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F23 Admin console, Taxonomy &amp; Tags (<c>taxonomy.manage</c>, web only): fields and topics (add, rename, reorder,
/// disable or enable; nothing is deleted) and tags (list, rename, merge, hide). Contract: "Taxonomy and tags".
/// </summary>
internal sealed class AdminTaxonomyEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var fields = api.MapGroup("/admin/fields").RequireAuthorization().WithTags("Admin");

        fields.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminTaxonomyQuery(), ct)).ToHttp(http))
            .WithSummary("Every field (disabled ones too) with all its topics, and the icons and colors clients draw (taxonomy.manage)")
            .Produces<AdminTaxonomyDto>();

        fields.MapPost("/", async (CreateFieldRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreateFieldCommand(
                    body.Slug, body.NameAr, body.NameEn, body.Icon, body.Color, body.IsSensitive, body.RequiresSources, body.IsEnabled), ct);
                return result.IsSuccess ? TypedResults.Created("/api/v1/admin/fields", result.Value) : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Add a field, last in the order; 409 field.slug_taken (taxonomy.manage)")
            .Produces<AdminFieldDto>(StatusCodes.Status201Created);

        // Before "/{id:guid}" so "order" never reaches it (the guid constraint keeps them apart anyway).
        fields.MapPut("/order", async (OrderRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ReorderFieldsCommand(body.Ids ?? []), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Every field once, in display order; 400 admin.order_invalid (taxonomy.manage)");

        fields.MapPut("/{id:guid}", async (Guid id, UpdateFieldRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UpdateFieldCommand(
                    id, body.NameAr, body.NameEn, body.Icon, body.Color, body.IsSensitive, body.RequiresSources, body.IsEnabled), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Rename, restyle, disable or enable a field; the slug never changes (taxonomy.manage)")
            .Produces<AdminFieldDto>();

        fields.MapPut("/{id:guid}/topics/order", async (Guid id, OrderRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ReorderTopicsCommand(id, body.Ids ?? []), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Every topic of the field once, in display order; 400 admin.order_invalid (taxonomy.manage)");

        var topics = api.MapGroup("/admin/topics").RequireAuthorization().WithTags("Admin");

        topics.MapPost("/", async (CreateTopicRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreateTopicCommand(body.FieldId, body.Slug, body.NameAr, body.NameEn, body.IsEnabled), ct);
                return result.IsSuccess ? TypedResults.Created("/api/v1/admin/fields", result.Value) : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Add a topic, last in its field; 404 field.not_found, 409 topic.slug_taken (taxonomy.manage)")
            .Produces<AdminTopicDto>(StatusCodes.Status201Created);

        topics.MapPut("/{id:guid}", async (Guid id, UpdateTopicRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UpdateTopicCommand(id, body.NameAr, body.NameEn, body.IsEnabled), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Rename, disable or enable a topic; the slug never changes (taxonomy.manage)")
            .Produces<AdminTopicDto>();

        var tags = api.MapGroup("/admin/tags").RequireAuthorization().WithTags("Admin");

        tags.MapGet("/", async (string? q, string? status, string? origin, string? sort, int? page, int? pageSize, ISender sender,
                    HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetAdminTagsQuery(q, status, origin, sort, page, pageSize), ct)).ToHttp(http))
            .WithSummary("Tags with counts and aliases: q, status=all|visible|hidden, origin=all|system|user, sort=articles|name|newest, offset pages (taxonomy.manage)")
            .Produces<PagedList<AdminTagDto>>();

        tags.MapPut("/{id:guid}", async (Guid id, RenameTagRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new RenameTagCommand(id, body.Name), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Rename a tag; the slug stays and the old spelling becomes an alias. 409 tag.name_taken with tagId/tagSlug (taxonomy.manage)")
            .Produces<AdminTagDto>();

        tags.MapPost("/{id:guid}/merge", async (Guid id, MergeTagRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new MergeTagCommand(id, body.IntoTagId), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Merge the tag into intoTagId (can't be undone): articles move, name and slug become aliases (taxonomy.manage)")
            .Produces<AdminTagDto>();

        tags.MapPut("/{id:guid}/hidden", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetTagHiddenCommand(id, Hidden: true), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Hide a tag (idempotent): not suggested, not shown, its page 404 (taxonomy.manage)")
            .Produces<AdminTagDto>();

        tags.MapDelete("/{id:guid}/hidden", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SetTagHiddenCommand(id, Hidden: false), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unhide a tag (idempotent) (taxonomy.manage)")
            .Produces<AdminTagDto>();
    }
}
