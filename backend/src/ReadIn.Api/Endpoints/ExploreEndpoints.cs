using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Explore;
using ReadIn.Application.Features.Follows;

namespace ReadIn.Api.Endpoints;

/// <summary>Explore and the field pages (SPEC F15; contract-v1 "Explore and field pages"). Guests are allowed.</summary>
internal sealed class ExploreEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var explore = api.MapGroup("/explore").WithTags("Explore").AllowAnonymous();

        explore.MapGet("/", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetExploreQuery(user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Every section of the Explore page: fields, trending this week, most saved, new writers, featured paths")
            .Produces<ExploreDto>();

        explore.MapGet("/trending", async (string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetTrendingArticlesQuery(cursor, limit ?? ExploreLimits.DefaultLimit, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Trending this week, best first: engagement in the last 7 days, then the quality score (at most 100)")
            .Produces<CursorPage<ArticleCardDto>>();

        explore.MapGet("/most-saved", async (string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMostSavedArticlesQuery(cursor, limit ?? ExploreLimits.DefaultLimit, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Most saved, best first: saves in the last 30 days, then all-time saves (at most 100)")
            .Produces<CursorPage<ArticleCardDto>>();

        var fields = api.MapGroup("/fields").WithTags("Explore").AllowAnonymous();

        fields.MapGet("/{slug}", async (string slug, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFieldPageQuery(slug, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("A field page's header and topic chips; 404 field.not_found when unknown or disabled")
            .Produces<FieldPageDto>();

        fields.MapGet("/{slug}/articles", async (
                    string slug, string? topic, string? cursor, int? limit, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFieldArticlesQuery(slug, topic, cursor, limit ?? ExploreLimits.DefaultLimit, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("The field's articles (or one topic's), newest first, as cards; 404 topic.not_found for a topic of another field")
            .Produces<CursorPage<ArticleCardDto>>();

        fields.MapGet("/{slug}/writers", async (string slug, int? limit, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetFieldWritersQuery(slug, limit ?? ExploreLimits.MaxTopWriters), ct)).ToHttp(http))
            .WithSummary("Top writers in the field: reads and reactions on their articles there in the last 90 days")
            .Produces<IReadOnlyList<UserSummaryDto>>();
    }
}
