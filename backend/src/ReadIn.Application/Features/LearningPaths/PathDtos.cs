using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.LearningPaths;

/// <summary>A learning path as cards and lists show it (SPEC F09).</summary>
public record PathCardDto
{
    public Guid Id { get; init; }
    public string Slug { get; init; } = default!;

    /// <summary>In the UI language.</summary>
    public string Title { get; init; } = default!;

    public string? Description { get; init; }
    public FieldRefDto Field { get; init; } = default!;

    /// <summary>Articles a reader can open, in path order.</summary>
    public int ArticleCount { get; init; }

    /// <summary>Sum of their reading times, in the versions served to the caller.</summary>
    public int ReadingTimeMinutes { get; init; }

    /// <summary>Absolute; the first article's cover.</summary>
    public string? CoverUrl { get; init; }

    /// <summary>Signed-in callers (also when not enrolled); on a profile, that user's. Null for guests.</summary>
    public PathProgressDto? Progress { get; init; }

    /// <summary>Null when not enrolled, and for guests.</summary>
    public PathEnrollmentDto? Enrollment { get; init; }
}

/// <param name="Next">The first unread article in path order; null when every article is read.</param>
public sealed record PathProgressDto(int ReadCount, int Total, int Percent, PathArticleRefDto? Next)
{
    public static int PercentOf(int readCount, int total) => total == 0 ? 0 : Math.Clamp(readCount * 100 / total, 0, 100);
}

/// <param name="CompletedAt">Every article was read while enrolled: the completion badge. It stays when the path grows.</param>
public sealed record PathEnrollmentDto(DateTime EnrolledAt, DateTime? CompletedAt);

/// <summary>A light article reference inside a path.</summary>
/// <param name="Position">1-based place in the path.</param>
public sealed record PathArticleRefDto(Guid Id, string Slug, string Title, string Language, int Position, int ReadingTimeMinutes);

/// <param name="Position">1-based and dense, in path order.</param>
/// <param name="IsRead">False for guests.</param>
public sealed record PathItemDto(int Position, ArticleCardDto Article, bool IsRead);

public sealed record PathDetailsDto : PathCardDto
{
    public IReadOnlyList<PathItemDto> Items { get; init; } = [];
}

/// <summary>GET /articles/{id}/path: the "Next in path" block at the end of the reader.</summary>
/// <param name="Next">The following article in path order, read or not; null on the last one.</param>
public sealed record ArticlePathDto(PathCardDto Path, int Position, int Total, PathArticleRefDto? Previous, ArticleCardDto? Next);

/// <summary>GET /admin/paths (permission <c>paths.manage</c>).</summary>
public sealed record AdminPathDto(
    Guid Id,
    string Slug,
    Guid FieldId,
    string TitleAr,
    string TitleEn,
    string? DescriptionAr,
    string? DescriptionEn,
    int SortOrder,
    bool IsPublished,
    bool IsEditorial,
    IReadOnlyList<Guid> ArticleIds,
    int EnrollmentCount);
