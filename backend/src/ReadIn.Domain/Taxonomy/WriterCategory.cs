using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

/// <summary>
/// A writer's own category (SPEC F31, "أقسام الكاتب"): a way to group their articles, apart from the platform-wide fields
/// and topics. An article has zero or one, for all its language versions. <see cref="NormalizedName"/> (lower case +
/// Arabic normalization, SPEC §22) is unique per writer; <see cref="Slug"/> is made once from the first name, is unique
/// per writer and never changes on rename, so links keep working. Only a moderator clearing an offensive name changes it.
/// </summary>
public sealed class WriterCategory : Entity
{
    public const int MaxPerWriter = 50;
    public const int MaxNameLength = 40;

    /// <summary>Column sizes: a name has at most 40 characters; its normalized form never grows, a slug may (<c>#</c> → <c>sharp</c>).</summary>
    public const int NameColumnLength = 64;
    public const int SlugColumnLength = 100;

    private WriterCategory() { } // EF

    /// <param name="sortOrder">Its place in the writer's order: categories are listed by ascending <see cref="SortOrder"/>.</param>
    public WriterCategory(Guid userId, string name, string normalizedName, string slug, int sortOrder, DateTime createdAt)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        ArgumentException.ThrowIfNullOrWhiteSpace(normalizedName);
        ArgumentException.ThrowIfNullOrWhiteSpace(slug);
        UserId = userId;
        Name = name;
        NormalizedName = normalizedName;
        Slug = slug;
        SortOrder = sortOrder;
        CreatedAt = createdAt;
    }

    public Guid UserId { get; private set; }
    public string Name { get; private set; } = default!;
    public string NormalizedName { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public int SortOrder { get; private set; }
    public DateTime CreatedAt { get; private set; }

    /// <summary>A new name; the slug stays.</summary>
    public void Rename(string name, string normalizedName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        ArgumentException.ThrowIfNullOrWhiteSpace(normalizedName);
        Name = name;
        NormalizedName = normalizedName;
    }

    public void MoveTo(int sortOrder) => SortOrder = sortOrder;

    /// <summary>
    /// A moderator cleared an offensive name (SPEC F31, F22): a neutral placeholder, and a new slug made from it, because the
    /// old slug held the name.
    /// </summary>
    public void ClearName(string placeholder, string normalizedName, string slug)
    {
        Rename(placeholder, normalizedName);
        ArgumentException.ThrowIfNullOrWhiteSpace(slug);
        Slug = slug;
    }
}

public static class WriterCategoryErrors
{
    public static readonly Error NotFound = Error.NotFound("category.not_found", "Category not found.");

    /// <summary>Another writer's category: only its owner sees or uses it.</summary>
    public static readonly Error NotOwner = Error.Forbidden("category.not_owner", "This category isn't yours.");

    public static readonly Error Limit = Error.Validation(
        "category.limit", $"You can have at most {WriterCategory.MaxPerWriter} categories.");

    public static readonly Error NameTaken = Error.Conflict("category.name_taken", "You already have a category with this name.");

    /// <summary>A validation code (in <c>errors.name</c>): 1–40 characters with at least one letter or digit.</summary>
    public const string NameInvalidCode = "category.name_invalid";
}
