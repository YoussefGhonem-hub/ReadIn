using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Features.Seo;

namespace ReadIn.Api.Endpoints;

/// <summary>SPEC §23: what the web's <c>/sitemap.xml</c> lists. Public, cached.</summary>
internal sealed class SeoEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/sitemap", async (ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetSitemapQuery(), ct)).ToHttp(http))
            .WithTags("SEO")
            .AllowAnonymous()
            .WithSummary("Every public page for the web's sitemap.xml: article versions, writers, categories, fields, tags, paths")
            .Produces<SitemapDto>();
    }
}
