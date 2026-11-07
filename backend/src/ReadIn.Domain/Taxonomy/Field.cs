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

    /// <summary>Medicine / Public Health: readers see a health disclaimer (SPEC F04). It never blocks publishing (F06).</summary>
    public bool IsSensitive { get; private set; }

    /// <summary>Software, Medicine and Health articles must cite sources (SPEC F05).</summary>
    public bool RequiresSources { get; private set; }

    public bool IsEnabled { get; private set; }

    /// <summary>
    /// The first change made in the admin console (SPEC F23, §18); from then on the taxonomy seeder leaves the row alone.
    /// Null while the row only follows <c>content/taxonomy.yaml</c>.
    /// </summary>
    public DateTime? CustomizedAt { get; private set; }

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

    /// <summary>A field added in the admin console (SPEC F23): customized from the start, so the seeder never touches it.</summary>
    public static Field CreateByAdmin(
        string slug, string nameAr, string nameEn, string icon, string color, int sortOrder, bool isSensitive, bool requiresSources,
        bool isEnabled, DateTime now) =>
        new(slug, nameAr, nameEn, icon, color, sortOrder)
        {
            IsSensitive = isSensitive,
            RequiresSources = requiresSources,
            IsEnabled = isEnabled,
            CustomizedAt = now,
        };

    /// <summary>
    /// An admin's edit (SPEC F23); the slug never changes. Returns the names of the properties that changed (empty: nothing
    /// changed and nothing is marked); otherwise the row becomes customized.
    /// </summary>
    public IReadOnlyList<string> EditByAdmin(
        string nameAr, string nameEn, string icon, string color, bool isSensitive, bool requiresSources, bool isEnabled, DateTime now)
    {
        var changed = new List<string>();
        if (NameAr != nameAr) changed.Add("nameAr");
        if (NameEn != nameEn) changed.Add("nameEn");
        if (Icon != icon) changed.Add("icon");
        if (Color != color) changed.Add("color");
        if (IsSensitive != isSensitive) changed.Add($"isSensitive={isSensitive.ToString().ToLowerInvariant()}");
        if (RequiresSources != requiresSources) changed.Add($"requiresSources={requiresSources.ToString().ToLowerInvariant()}");
        if (IsEnabled != isEnabled) changed.Add($"isEnabled={isEnabled.ToString().ToLowerInvariant()}");
        if (changed.Count == 0) return changed;

        NameAr = nameAr;
        NameEn = nameEn;
        Icon = icon;
        Color = color;
        IsSensitive = isSensitive;
        RequiresSources = requiresSources;
        IsEnabled = isEnabled;
        Customize(now);
        return changed;
    }

    /// <summary>The admin console's order (SPEC F23); returns whether it moved.</summary>
    public bool MoveTo(int sortOrder, DateTime now)
    {
        if (SortOrder == sortOrder) return false;
        SortOrder = sortOrder;
        Customize(now);
        return true;
    }

    /// <summary>Marks the row as changed in the console; the first time is kept.</summary>
    public void Customize(DateTime now) => CustomizedAt ??= now;

    /// <summary>A topic added in the admin console (SPEC F23), last in the field and customized from the start.</summary>
    public Topic AddTopicByAdmin(string slug, string nameAr, string nameEn, bool isEnabled, DateTime now)
    {
        var sortOrder = _topics.Count == 0 ? 1 : _topics.Max(t => t.SortOrder) + 1;
        var topic = new Topic(Id, slug, nameAr, nameEn, sortOrder);
        topic.InitializeByAdmin(isEnabled, now);
        _topics.Add(topic);
        return topic;
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

    /// <summary>A disabled topic leaves topic lists, chips, the editor's picker and search; its articles keep it (SPEC F23).</summary>
    public bool IsEnabled { get; private set; } = true;

    /// <summary>The first change made in the admin console (SPEC F23); the taxonomy seeder leaves the row alone from then on.</summary>
    public DateTime? CustomizedAt { get; private set; }

    internal void InitializeByAdmin(bool isEnabled, DateTime now)
    {
        IsEnabled = isEnabled;
        CustomizedAt = now;
    }

    /// <summary>An admin's edit (SPEC F23): returns the names of the properties that changed (empty: nothing changed).</summary>
    public IReadOnlyList<string> EditByAdmin(string nameAr, string nameEn, bool isEnabled, DateTime now)
    {
        var changed = new List<string>();
        if (NameAr != nameAr) changed.Add("nameAr");
        if (NameEn != nameEn) changed.Add("nameEn");
        if (IsEnabled != isEnabled) changed.Add($"isEnabled={isEnabled.ToString().ToLowerInvariant()}");
        if (changed.Count == 0) return changed;

        NameAr = nameAr;
        NameEn = nameEn;
        IsEnabled = isEnabled;
        CustomizedAt ??= now;
        return changed;
    }

    /// <summary>The admin console's order (SPEC F23); returns whether it moved.</summary>
    public bool MoveTo(int sortOrder, DateTime now)
    {
        if (SortOrder == sortOrder) return false;
        SortOrder = sortOrder;
        CustomizedAt ??= now;
        return true;
    }

    internal void Update(string nameAr, string nameEn, int sortOrder)
    {
        NameAr = nameAr;
        NameEn = nameEn;
        SortOrder = sortOrder;
    }
}
