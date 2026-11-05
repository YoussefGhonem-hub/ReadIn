using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Application.Features.Follows;

namespace ReadIn.Application.Features.Search;

/// <summary>
/// The tabs of <c>GET /search?type=</c> (SPEC F16, <c>docs/api/contract-v1.md</c> "Search") and what each lists:
/// <see cref="SearchArticleDto"/>, <see cref="UserSummaryDto"/>, <see cref="SearchTopicDto"/> or <see cref="TagDto"/>.
/// </summary>
public static class SearchTypes
{
    public const string Articles = "articles";
    public const string Users = "users";
    public const string Topics = "topics";
    public const string Tags = "tags";

    public static readonly IReadOnlyList<string> All = [Articles, Users, Topics, Tags];

    public static bool IsValid(string? type) => type is Articles or Users or Topics or Tags;
}

/// <summary>The numbers the contract promises.</summary>
public static class SearchLimits
{
    /// <summary><c>q</c> after cleaning: 1–100 UTF-16 code units with a letter or digit (<c>search.query_invalid</c>).</summary>
    public const int MaxQueryLength = 100;

    /// <summary>Words of <c>q</c> that count; the rest are ignored.</summary>
    public const int MaxWords = 8;

    public const int DefaultLimit = 20;
    public const int MaxLimit = 50;

    /// <summary>Results one query pages through; then <c>nextCursor</c> is null.</summary>
    public const int MaxResults = 200;

    /// <summary>Results of each type in <see cref="SearchSuggestionsDto"/>.</summary>
    public const int SuggestionsPerType = 3;

    /// <summary>Highest <c>minMinutes</c> / <c>maxMinutes</c> (<c>search.filter_invalid</c> above it).</summary>
    public const int MaxMinutes = 600;
}

/// <summary>
/// Where an article matched, best first: the served version's title, its title + text (<c>SearchText</c>), or only the
/// attached PDF's text (<c>ExtractedText</c>, F26): the row then says it was found in the attached PDF.
/// </summary>
public enum SearchMatch
{
    Title = 0,
    Text = 1,
    Attachment = 2,
}

public enum SearchTopicKind
{
    Field = 0,
    Topic = 1,
}

/// <summary>
/// An article result: a normal card (with the caller's own state) in the version that matched, shown as the compact
/// row (F34), and where the query was found.
/// </summary>
public sealed record SearchArticleDto(ArticleCardDto Article, SearchMatch MatchedIn);

/// <summary>
/// A field or a topic result. It opens the field page: <c>/f/{FieldSlug}</c>, or <c>/f/{FieldSlug}?topic={TopicSlug}</c>
/// for a topic. <see cref="Name"/> and <see cref="FieldName"/> follow <c>Accept-Language</c>; <see cref="Icon"/> and
/// <see cref="Color"/> are the field's; <see cref="ArticleCount"/> counts the published articles readers can see in it.
/// </summary>
public sealed record SearchTopicDto(
    SearchTopicKind Kind,
    Guid Id,
    string Name,
    string NameAr,
    string NameEn,
    string FieldSlug,
    string? TopicSlug,
    string FieldName,
    string Icon,
    string Color,
    int ArticleCount);

/// <summary><c>GET /search/suggest</c>: at most <see cref="SearchLimits.SuggestionsPerType"/> of each type, ranked as in <c>/search</c>.</summary>
public sealed record SearchSuggestionsDto(
    IReadOnlyList<SearchArticleDto> Articles,
    IReadOnlyList<UserSummaryDto> Users,
    IReadOnlyList<SearchTopicDto> Topics,
    IReadOnlyList<TagDto> Tags);
