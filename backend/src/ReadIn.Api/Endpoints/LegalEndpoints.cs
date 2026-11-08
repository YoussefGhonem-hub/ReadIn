using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.ContentFilter;
using ReadIn.Application.Features.Legal;
using ReadIn.Application.Features.Users;

namespace ReadIn.Api.Endpoints;

/// <summary>
/// F37 Terms acceptance and the content filter (SPEC §17.2 "Legal &amp; content filter"): the terms version and pages, accepting
/// a newer version, and the console's word lists (<c>system.settings</c>).
/// </summary>
internal sealed class LegalEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/legal", async (ISender sender, HttpContext http, CancellationToken ct) =>
            {
                var result = await sender.Send(new GetLegalQuery(), ct);
                if (result.IsSuccess) http.Response.Headers.CacheControl = "public, max-age=300";
                return result.ToHttp(http);
            })
            .AllowAnonymous()
            .WithTags("Legal")
            .WithSummary("The current Terms of Use version, what changed, and the legal pages' paths on the web")
            .Produces<LegalDto>();

        api.MapPost("/me/terms/accept", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new AcceptTermsCommand(), ct)).ToHttp(http))
            .RequireAuthorization()
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithTags("Me")
            .WithSummary("Accept the current Terms of Use version (idempotent); returns the refreshed profile")
            .Produces<MeDto>();

        var filter = api.MapGroup("/admin/content-filter").RequireAuthorization().WithTags("Admin");

        filter.MapGet("/", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetContentFilterQuery(), ct)).ToHttp(http))
            .WithSummary("Admins (system.settings): every content filter term, enabled or not")
            .Produces<ContentFilterDto>();

        filter.MapPut("/", async (UpdateContentFilterRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UpdateContentFilterCommand(body.Terms), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Admins (system.settings): the whole enabled list; terms left out are disabled; audited")
            .Produces<ContentFilterDto>();

        filter.MapPost("/test", async (ContentFilterTestRequest body, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new TestContentFilterQuery(body.Text), ct)).ToHttp(http))
            .WithSummary("Admins (system.settings): what the filter makes of a text, with the matched terms")
            .Produces<ContentFilterTestDto>();
    }
}

/// <summary>Body of PUT /admin/content-filter.</summary>
internal sealed record UpdateContentFilterRequest(IReadOnlyList<ContentFilterTermInput>? Terms);

/// <summary>Body of POST /admin/content-filter/test.</summary>
internal sealed record ContentFilterTestRequest(string? Text);
