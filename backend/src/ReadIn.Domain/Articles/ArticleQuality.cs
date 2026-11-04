namespace ReadIn.Domain.Articles;

/// <summary>
/// The quality score that ranks Today's article (SPEC F07, ADR 0015): engagement, read completion and freshness, each in
/// [0, 1], weighted into a score in [0, 1]. <c>ArticleQualityJob</c> runs the same formula in SQL every hour; this is the
/// reference its tests compare against.
/// </summary>
public static class ArticleQuality
{
    public const double EngagementWeight = 0.45;
    public const double CompletionWeight = 0.35;
    public const double FreshnessWeight = 0.20;

    /// <summary>Weighted interactions (reactions + 2 × comments + 3 × saves) at which engagement is 0.5.</summary>
    public const double EngagementHalfPoint = 10;

    /// <summary>Freshness halves every 30 days.</summary>
    public const double FreshnessHalfLifeHours = 30 * 24;

    /// <param name="completedReads">Reads that met the F04 rule (≥ 70% and ≥ 30 s).</param>
    /// <param name="startedReads">Readers who opened it (one progress row each).</param>
    /// <param name="hoursSincePublish">Hours since the first publish.</param>
    public static double Score(int reactions, int comments, int saves, int completedReads, int startedReads, double hoursSincePublish)
    {
        var interactions = reactions + 2.0 * comments + 3.0 * saves;
        var engagement = 1.0 - 1.0 / (1.0 + interactions / EngagementHalfPoint);

        // Laplace smoothing: a new article starts at 0.5 instead of swinging between 0 and 1 on its first readers.
        var completion = (completedReads + 1.0) / (Math.Max(startedReads, completedReads) + 2.0);

        var freshness = Math.Pow(0.5, Math.Max(hoursSincePublish, 0) / FreshnessHalfLifeHours);

        return EngagementWeight * engagement + CompletionWeight * completion + FreshnessWeight * freshness;
    }
}
