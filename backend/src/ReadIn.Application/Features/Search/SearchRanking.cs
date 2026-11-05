namespace ReadIn.Application.Features.Search;

/// <summary>
/// The article ranking of contract-v1 ("Search"):
/// <c>score = place × (0.5 + 0.5 × rank) × (0.5 + QualityScore) × 1 ÷ (1 + days since the first publish ÷ 365)</c>.
/// </summary>
public static class SearchRanking
{
    public const double TitleWeight = 1.0;
    public const double TextWeight = 0.6;
    public const double AttachmentWeight = 0.4;

    /// <summary>Freshness halves after this many days, then keeps falling slowly (0.33 after two years).</summary>
    public const double FreshnessDays = 365;

    public static double PlaceWeight(SearchMatch place) => place switch
    {
        SearchMatch.Title => TitleWeight,
        SearchMatch.Text => TextWeight,
        _ => AttachmentWeight,
    };

    /// <param name="place">Where it matched (<c>matchedIn</c>).</param>
    /// <param name="rank">The engine's rank, 0–1 (<see cref="SearchHit.Rank"/>).</param>
    /// <param name="qualityScore">The article's F07 quality score, 0–1.</param>
    /// <param name="publishedAt">The first publish.</param>
    /// <param name="now">The time of the search.</param>
    public static double Score(SearchMatch place, double rank, double qualityScore, DateTime publishedAt, DateTime now)
    {
        var relevance = PlaceWeight(place) * (0.5 + 0.5 * Math.Clamp(rank, 0, 1));
        var quality = 0.5 + Math.Clamp(qualityScore, 0, 1);
        var days = Math.Max((now - publishedAt).TotalDays, 0);
        var freshness = 1 / (1 + days / FreshnessDays);
        return relevance * quality * freshness;
    }
}
