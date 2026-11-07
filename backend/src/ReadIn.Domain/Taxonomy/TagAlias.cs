using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

/// <summary>
/// Another name that leads to a tag (SPEC F23, F32): the old spelling of a renamed tag, or the name and slug of a tag merged
/// into it. Writers who type it, and seed content that names it, get <see cref="TagId"/>; a merged tag's slug opens its
/// page. <see cref="NormalizedName"/> is unique among aliases, and the code keeps it from also being a tag's.
/// </summary>
public sealed class TagAlias : Entity
{
    private TagAlias() { } // EF

    /// <param name="slug">The merged tag's slug, so its links keep working; null for a renamed spelling.</param>
    public TagAlias(Guid tagId, string name, string normalizedName, string? slug, DateTime createdAt)
    {
        TagId = tagId;
        Name = name;
        NormalizedName = normalizedName;
        Slug = slug;
        CreatedAt = createdAt;
    }

    public Guid TagId { get; private set; }
    public string Name { get; private set; } = default!;
    public string NormalizedName { get; private set; } = default!;
    public string? Slug { get; private set; }
    public DateTime CreatedAt { get; private set; }

    /// <summary>A merge moves the merged tag's aliases to the tag it went into.</summary>
    public void MoveTo(Guid tagId) => TagId = tagId;
}
