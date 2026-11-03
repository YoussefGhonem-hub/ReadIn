using ReadIn.Domain.Common;

namespace ReadIn.Domain.Learning;

/// <summary>
/// A curated, ordered series of articles (F09), e.g. "أساسيات ASP.NET Core". Editorial paths come from
/// content/taxonomy.yaml; their items are the imported articles that name the path in meta.json.
/// </summary>
public sealed class LearningPath : Entity, IAuditable
{
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

    public string Slug { get; private set; } = default!;
    public Guid FieldId { get; private set; }
    public string TitleAr { get; private set; } = default!;
    public string TitleEn { get; private set; } = default!;
    public string? DescriptionAr { get; private set; }
    public string? DescriptionEn { get; private set; }
    public int SortOrder { get; private set; }

    /// <summary>A path is listed only when it has at least one published article.</summary>
    public bool IsPublished { get; private set; }

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
        IsPublished = _items.Count > 0;
    }
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
