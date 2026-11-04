using ReadIn.Domain.Common;

namespace ReadIn.Domain.Learning;

/// <summary>
/// A curated, ordered series of articles (F09), e.g. "أساسيات ASP.NET Core". Editorial paths come from
/// content/taxonomy.yaml; their items are the imported articles that name the path in meta.json, and only the content
/// seeder changes them. Admins create and manage the other paths (permission <c>paths.manage</c>).
/// </summary>
public sealed class LearningPath : Entity, IAuditable
{
    public const int MaxItems = 100;

    private readonly List<LearningPathItem> _items = [];

    private LearningPath() { } // EF

    public LearningPath(string slug, Guid fieldId, string titleAr, string titleEn, int sortOrder)
    {
        Slug = slug;
        FieldId = fieldId;
        TitleAr = titleAr;
        TitleEn = titleEn;
        SortOrder = sortOrder;
    }

    /// <summary>An editorial path, from content/taxonomy.yaml (seeder #7).</summary>
    public static LearningPath CreateEditorial(string slug, Guid fieldId, string titleAr, string titleEn, int sortOrder) =>
        new(slug, fieldId, titleAr, titleEn, sortOrder) { IsEditorial = true };

    public string Slug { get; private set; } = default!;
    public Guid FieldId { get; private set; }
    public string TitleAr { get; private set; } = default!;
    public string TitleEn { get; private set; } = default!;
    public string? DescriptionAr { get; private set; }
    public string? DescriptionEn { get; private set; }
    public int SortOrder { get; private set; }

    /// <summary>Listed to readers. Editorial paths are published while they hold an imported article; admin paths by <see cref="Publish"/>.</summary>
    public bool IsPublished { get; private set; }

    /// <summary>Managed in content/taxonomy.yaml: admins can't change it (<see cref="LearningPathErrors.Editorial"/>).</summary>
    public bool IsEditorial { get; private set; }

    public IReadOnlyCollection<LearningPathItem> Items => _items.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }

    public void Update(Guid fieldId, string titleAr, string titleEn, string? descriptionAr, string? descriptionEn, int sortOrder)
    {
        FieldId = fieldId;
        TitleAr = titleAr;
        TitleEn = titleEn;
        DescriptionAr = descriptionAr;
        DescriptionEn = descriptionEn;
        SortOrder = sortOrder;
    }

    /// <summary>Admin rename of an admin path (the slug is its URL).</summary>
    public void ChangeSlug(string slug) => Slug = slug;

    /// <summary>
    /// The content seeder's sync of an editorial path: marks it editorial, replaces its items and publishes it while it
    /// holds at least one imported article.
    /// </summary>
    public void SyncEditorial(IReadOnlyList<(Guid ArticleId, int Order)> articles)
    {
        IsEditorial = true;
        SetItems(articles);
        IsPublished = _items.Count > 0;
    }

    /// <summary>Replaces the items with <paramref name="articles"/> (article id + order), keeping existing rows when unchanged.</summary>
    public void SetItems(IReadOnlyList<(Guid ArticleId, int Order)> articles)
    {
        _items.RemoveAll(i => articles.All(a => a.ArticleId != i.ArticleId));
        foreach (var (articleId, order) in articles)
        {
            var existing = _items.FirstOrDefault(i => i.ArticleId == articleId);
            if (existing is null) _items.Add(new LearningPathItem(Id, articleId, order));
            else existing.MoveTo(order);
        }
    }

    /// <summary>Admin items: <paramref name="articleIds"/> in path order (1..N).</summary>
    public void SetItemsInOrder(IReadOnlyList<Guid> articleIds) =>
        SetItems([.. articleIds.Select((id, index) => (id, index + 1))]);

    /// <summary>Lists the path to readers; it needs at least one item.</summary>
    public Result Publish()
    {
        if (_items.Count == 0) return LearningPathErrors.Empty;
        IsPublished = true;
        return Result.Success();
    }

    public void Unpublish() => IsPublished = false;
}

public sealed class LearningPathItem : Entity
{
    private LearningPathItem() { } // EF

    internal LearningPathItem(Guid pathId, Guid articleId, int order)
    {
        PathId = pathId;
        ArticleId = articleId;
        Order = order;
    }

    public Guid PathId { get; private set; }
    public Guid ArticleId { get; private set; }
    public int Order { get; private set; }

    internal void MoveTo(int order) => Order = order;
}

/// <summary>A reader following a learning path (F09): "my paths", the Home card and the completion badge.</summary>
public sealed class PathEnrollment : Entity
{
    private PathEnrollment() { } // EF

    public PathEnrollment(Guid userId, Guid pathId, DateTime now)
    {
        UserId = userId;
        PathId = pathId;
        EnrolledAt = now;
        LastActivityAt = now;
    }

    public Guid UserId { get; private set; }
    public Guid PathId { get; private set; }
    public DateTime EnrolledAt { get; private set; }

    /// <summary>Enrolling, or reading one of the path's articles; the latest one is the "active" path.</summary>
    public DateTime LastActivityAt { get; private set; }

    /// <summary>Every article of the path was read while enrolled: the completion badge. It stays when the path grows.</summary>
    public DateTime? CompletedAt { get; private set; }

    public bool IsCompleted => CompletedAt is not null;

    public void RecordActivity(DateTime now)
    {
        if (now > LastActivityAt) LastActivityAt = now;
    }

    /// <summary>Marks the path completed when <paramref name="readCount"/> covers all <paramref name="total"/> articles.</summary>
    /// <returns>true when this call completed it.</returns>
    public bool CompleteIfDone(int readCount, int total, DateTime now)
    {
        if (CompletedAt is not null || total == 0 || readCount < total) return false;
        CompletedAt = now;
        return true;
    }

    /// <summary>Local demo data only (SPEC §18.2).</summary>
    public static PathEnrollment Seeded(Guid userId, Guid pathId, DateTime enrolledAt, DateTime lastActivityAt, DateTime? completedAt) =>
        new(userId, pathId, enrolledAt) { LastActivityAt = lastActivityAt, CompletedAt = completedAt };
}

public static class LearningPathErrors
{
    public static readonly Error NotFound = Error.NotFound("path.not_found", "Learning path not found.");
    public static readonly Error SlugTaken = Error.Conflict("path.slug_taken", "Another learning path uses this slug.");
    public static readonly Error Editorial = Error.Conflict("path.editorial", "This path is managed in content/taxonomy.yaml.");
    public static readonly Error ItemsInvalid = Error.Validation("path.items_invalid", "Give 1–100 different published articles.");
    public static readonly Error Empty = Error.Validation("path.items_invalid", "A path needs at least one article before it is published.");
}
