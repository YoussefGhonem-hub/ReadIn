using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Devotions;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F38 private devotions (SPEC §17.2, <c>docs/api/contract-v1.md</c> "Private devotions (F38)"): your own du'as. Bearer
/// only, <c>devotions.access</c> (the SuperAdmin) on every call; writes use the writes limit. Nothing is cached.
/// </summary>
internal sealed class DevotionEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Private devotions");

        me.MapGet("/duas", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetMyDuasQuery(), ct);
                http.Response.Headers.CacheControl = "no-store";
                return result.ToHttp(http);
            })
            .WithSummary("All your du'as, oldest first")
            .Produces<IReadOnlyList<PersonalDuaDto>>();

        me.MapPost("/duas", async (PersonalDuaRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new CreatePersonalDuaCommand(body.Title, body.Text, body.Repeat), ct);
                return result.IsSuccess
                    ? TypedResults.Created($"/api/v1/me/duas/{result.Value.Id}", result.Value)
                    : result.Error!.ToProblem(http);
            })
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Add a du'a, last (title 0–100 characters, text 1–2,000 kept as written, repeat 1–1,000; at most 200)")
            .Produces<PersonalDuaDto>(StatusCodes.Status201Created);

        me.MapPatch("/duas/{id:guid}", async (Guid id, PersonalDuaRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new EditPersonalDuaCommand(id, body.Title, body.Text, body.Repeat), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Replace a du'a's title, text and repeat count; a missing or empty title clears it")
            .Produces<PersonalDuaDto>();

        me.MapDelete("/duas/{id:guid}", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new DeletePersonalDuaCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Delete a du'a");
    }
}

/// <summary>Body of POST /me/duas and PATCH /me/duas/{id}. Nullable, so a missing text is the validation code validation.required.</summary>
internal sealed record PersonalDuaRequest(string? Title, string? Text, int? Repeat);
