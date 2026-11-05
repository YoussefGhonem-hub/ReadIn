using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

/// <summary>
/// A tag shared by every writer (SPEC F32). <see cref="NormalizedName"/> (lower case + Arabic normalization, SPEC §22) is
/// unique, so <c>AI</c> and <c>ai</c> are one tag that keeps its first spelling as <see cref="Name"/>. <see cref="Slug"/>
/// is made once and never changes.
/// </summary>
public sealed class Tag : Entity
{
    /// <summary>Column sizes: new names have at most 30 characters, older ones (before F32) up to 64.</summary>
    public const int NameColumnLength = 64;
    public const int SlugColumnLength = 100;

    private Tag() { } // EF

    /// <param name="createdById">The writer whose publish created it; null for a system tag from the seed content.</param>
    public Tag(string name, string normalizedName, string slug, Guid? createdById, DateTime createdAt)
    {
        Name = name;
        NormalizedName = normalizedName;
        Slug = slug;
        CreatedById = createdById;
        IsSystem = createdById is null;
        CreatedAt = createdAt;
    }

    public string Slug { get; private set; } = default!;
    public string Name { get; private set; } = default!;
    public string NormalizedName { get; private set; } = default!;

    /// <summary>From the seed content (SPEC §19): never deleted by the cleanup job.</summary>
    public bool IsSystem { get; private set; }

    /// <summary>The writer who created it; null for system tags and once that writer deleted the account (SPEC §9.6).</summary>
    public Guid? CreatedById { get; private set; }

    public DateTime CreatedAt { get; private set; }

    /// <summary>Hidden by <c>taxonomy.manage</c> (F23): not suggested, not shown, its page is 404. Its article links stay.</summary>
    public bool IsHidden { get; private set; }

    /// <summary>Since when no published article carries it (the daily cleanup job keeps this); null while it has one.</summary>
    public DateTime? EmptySince { get; private set; }

    /// <summary>The seed content uses it, so it stays even without articles.</summary>
    public void MarkSystem() => IsSystem = true;

    public void Hide() => IsHidden = true;

    public void Show() => IsHidden = false;

    /// <summary>Brings a tag from before F32 to the F32 rules (a one-time upgrade at startup).</summary>
    public void Upgrade(string name, string normalizedName, string slug, bool isSystem, Guid? createdById)
    {
        Name = name;
        NormalizedName = normalizedName;
        Slug = slug;
        IsSystem = isSystem;
        CreatedById = isSystem ? null : createdById;
    }
}
