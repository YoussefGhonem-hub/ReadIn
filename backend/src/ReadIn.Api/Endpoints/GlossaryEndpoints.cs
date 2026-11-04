using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Queries.GetRelatedArticles;
using ReadIn.Application.Features.Glossary;
using ReadIn.Application.Features.Glossary.Queries.GetGlossaryTerm;
using ReadIn.Application.Features.Glossary.Queries.SearchGlossary;

namespace ReadIn.Api.Endpoints;

/// <summary>The glossary behind term taps in the reader (SPEC F21).</summary>
internal sealed class GlossaryEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var glossary = api.MapGroup("/glossary").WithTags("Glossary").AllowAnonymous();

        glossary.MapGet("/", async (string? q, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SearchGlossaryQuery(q, limit ?? SearchGlossaryQuery.DefaultLimit), ct)).ToHttp(http))
            .WithSummary("Terms whose English name or id contains q, those starting with it first, then A–Z (the editor's term picker)")
            .Produces<IReadOnlyList<GlossaryTermSummaryDto>>();

        glossary.MapGet("/{slug}", async (string slug, string? lang, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetGlossaryTermQuery(slug, lang, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("A term's definitions and up to 6 published articles that use it; ?lang= picks the article titles")
            .Produces<GlossaryTermDto>();
    }
}

/// <summary>The end of the reader (SPEC F04): related articles. "Next in path" is served by the learning paths (F09).</summary>
internal sealed class RelatedArticlesEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        api.MapGet("/articles/{id:guid}/related", async (Guid id, string? lang, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetRelatedArticlesQuery(id, lang, limit ?? GetRelatedArticlesQuery.DefaultLimit, user.UiLanguage), ct)).ToHttp(http))
            .AllowAnonymous()
            .WithTags("Articles")
            .WithSummary("Up to `limit` (1–10, default 4) articles related to this one: same topic, field, tags and glossary terms")
            .Produces<IReadOnlyList<ArticleCardDto>>();
    }
}
