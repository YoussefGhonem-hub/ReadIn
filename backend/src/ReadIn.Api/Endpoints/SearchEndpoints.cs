using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Search;

namespace ReadIn.Api.Endpoints;

/// <summary>Search (SPEC F16, §22; contract-v1 "Search"): one tab at a time, and the as-you-type suggestions.</summary>
internal sealed class SearchEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var search = api.MapGroup("/search").WithTags("Search").AllowAnonymous().RequireRateLimiting(RateLimitPolicies.Search);

        search.MapGet("/", async (
                    string? q, string? type, string? field, string? lang, int? minMinutes, int? maxMinutes, string? cursor, int? limit,
                    ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                {
                    var size = limit ?? SearchLimits.DefaultLimit;
                    return (string.IsNullOrWhiteSpace(type) ? SearchTypes.Articles : type.Trim().ToLowerInvariant()) switch
                    {
                        SearchTypes.Articles => (await sender.Send(
                            new ArticleSearchQuery(q, field, lang, minMinutes, maxMinutes, cursor, size, user.UiLanguage), ct)).ToHttp(http),
                        SearchTypes.Users => (await sender.Send(new UserSearchQuery(q, cursor, size), ct)).ToHttp(http),
                        SearchTypes.Topics => (await sender.Send(new TopicSearchQuery(q, cursor, size, user.UiLanguage), ct)).ToHttp(http),
                        SearchTypes.Tags => (await sender.Send(new TagSearchQuery(q, cursor, size), ct)).ToHttp(http),
                        _ => SearchErrors.TypeInvalid.ToProblem(http),
                    };
                })
            .WithSummary("Search one type, best first: articles (default) → CursorPage<SearchArticleDto>, users → CursorPage<UserSummaryDto>, "
                + "topics → CursorPage<SearchTopicDto>, tags → CursorPage<TagDto>. field, lang, minMinutes and maxMinutes filter articles")
            // One 200 schema per operation: the other types' items are the schemas of /search/suggest.
            .Produces<CursorPage<SearchArticleDto>>();

        search.MapGet("/suggest", async (string? q, ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new SearchSuggestionsQuery(q, user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("The first 3 results of each type for the as-you-type dropdown, ranked as in /search")
            .Produces<SearchSuggestionsDto>();
    }
}
