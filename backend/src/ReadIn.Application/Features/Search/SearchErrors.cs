using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Search;

/// <summary>Search (F16) error codes (contract-v1 "Search"); clients translate them.</summary>
public static class SearchErrors
{
    /// <summary><c>q</c> is empty, longer than 100 characters after cleaning, or has no letter or digit.</summary>
    public static readonly Error QueryInvalid = Error.Validation(
        "search.query_invalid", "Type 1–100 characters, with at least one letter or digit.");

    /// <summary><c>type</c> isn't articles, users, topics or tags.</summary>
    public static readonly Error TypeInvalid = Error.Validation(
        "search.type_invalid", "The search type must be articles, writers, topics or tags.");

    /// <summary>A bad <c>lang</c>, reading time outside 0–600, or <c>minMinutes</c> above <c>maxMinutes</c>.</summary>
    public static readonly Error FilterInvalid = Error.Validation(
        "search.filter_invalid", "These search filters aren't valid.");
}
