using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

/// <summary>A knowledge field such as ".NET" or "Machine Learning" (SPEC §1.4, §19.1).</summary>
public sealed class Field : Entity, IAuditable
{
    private readonly List<Topic> _topics = [];

    private Field() { } // EF

    public Field(string slug, string nameAr, string nameEn, string icon, string color, int sortOrder)
    {
        Slug = slug;
        NameAr = nameAr;
        NameEn = nameEn;
        Icon = icon;
        Color = color;
        SortOrder = sortOrder;
        IsEnabled = true;
        RequiresSources = true;
    }

    public string Slug { get; private set; } = default!;
    public string NameAr { get; private set; } = default!;
    public string NameEn { get; private set; } = default!;
    public string Icon { get; private set; } = default!;
    public string Color { get; private set; } = default!;
    public int SortOrder { get; private set; }

    /// <summary>Medicine / Public Health: publishing needs a VerifiedWriter and reviewer approval (SPEC F06).</summary>
    public bool IsSensitive { get; private set; }

    /// <summary>Software, Medicine and Health articles must cite sources (SPEC F05).</summary>
    public bool RequiresSources { get; private set; }

    public bool IsEnabled { get; private set; }

    public IReadOnlyCollection<Topic> Topics => _topics.AsReadOnly();

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }

    public void Update(string nameAr, string nameEn, string icon, string color, int sortOrder, bool isSensitive, bool requiresSources, bool isEnabled)
    {
        NameAr = nameAr;
        NameEn = nameEn;
        Icon = icon;
        Color = color;
        SortOrder = sortOrder;
        IsSensitive = isSensitive;
        RequiresSources = requiresSources;
        IsEnabled = isEnabled;
    }

    public Topic UpsertTopic(string slug, string nameAr, string nameEn, int sortOrder)
    {
        var topic = _topics.FirstOrDefault(t => t.Slug == slug);
        if (topic is null)
        {
            topic = new Topic(Id, slug, nameAr, nameEn, sortOrder);
            _topics.Add(topic);
        }
        else
        {
            topic.Update(nameAr, nameEn, sortOrder);
        }
        return topic;
    }
}

public sealed class Topic : Entity
{
    private Topic() { } // EF

    internal Topic(Guid fieldId, string slug, string nameAr, string nameEn, int sortOrder)
    {
        FieldId = fieldId;
        Slug = slug;
        NameAr = nameAr;
        NameEn = nameEn;
        SortOrder = sortOrder;
    }

    public Guid FieldId { get; private set; }
    public string Slug { get; private set; } = default!;
    public string NameAr { get; private set; } = default!;
    public string NameEn { get; private set; } = default!;
    public int SortOrder { get; private set; }

    internal void Update(string nameAr, string nameEn, int sortOrder)
    {
        NameAr = nameAr;
        NameEn = nameEn;
        SortOrder = sortOrder;
    }
}

public sealed class Tag : Entity
{
    private Tag() { } // EF

    public Tag(string slug, string name)
    {
        Slug = slug;
        Name = name;
    }

    public string Slug { get; private set; } = default!;
    public string Name { get; private set; } = default!;

    public static string ToSlug(string name) =>
        new string(name.Trim().ToLowerInvariant().Select(c => char.IsLetterOrDigit(c) || c is '+' or '#' or '.' ? c : '-').ToArray())
            .Trim('-');
}
