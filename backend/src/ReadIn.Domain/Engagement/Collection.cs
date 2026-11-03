using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A named list of saved articles (SPEC F13), e.g. "Interview prep". Deleting it keeps the articles saved; unsaving an
/// article removes it from every collection.
/// </summary>
public sealed class Collection : AggregateRoot
{
    public const int MaxPerUser = 50;
    public const int MaxNameLength = 60;

    private readonly List<CollectionItem> _items = [];

    private Collection() { } // EF

    public Guid UserId { get; private set; }
    public string Name { get; private set; } = default!;
    public DateTime CreatedAt { get; private set; }

    public IReadOnlyCollection<CollectionItem> Items => _items.AsReadOnly();

    /// <param name="existingCount">How many collections the user has now; at most <see cref="MaxPerUser"/>.</param>
    public static Result<Collection> Create(Guid userId, string name, int existingCount, DateTime now)
    {
        if (existingCount >= MaxPerUser) return CollectionErrors.LimitReached;
        return new Collection { UserId = userId, Name = NormalizeName(name), CreatedAt = now };
    }

    public void Rename(string name) => Name = NormalizeName(name);

    /// <returns>false when the article was already in the collection.</returns>
    public bool AddArticle(Guid articleId, DateTime now)
    {
        if (_items.Any(i => i.ArticleId == articleId)) return false;
        _items.Add(new CollectionItem(Id, articleId, now));
        return true;
    }

    /// <returns>false when the article was not in the collection.</returns>
    public bool RemoveArticle(Guid articleId) => _items.RemoveAll(i => i.ArticleId == articleId) > 0;

    /// <summary>Trimmed, 1–60 characters. Requests are validated first, so a bad name here is a programming error.</summary>
    public static string NormalizeName(string name)
    {
        var trimmed = name?.Trim();
        ArgumentException.ThrowIfNullOrEmpty(trimmed, nameof(name));
        if (trimmed.Length > MaxNameLength)
            throw new ArgumentOutOfRangeException(nameof(name), $"A collection name has at most {MaxNameLength} characters.");
        return trimmed;
    }
}

public sealed class CollectionItem
{
    private CollectionItem() { } // EF

    internal CollectionItem(Guid collectionId, Guid articleId, DateTime addedAt)
    {
        CollectionId = collectionId;
        ArticleId = articleId;
        AddedAt = addedAt;
    }

    public Guid CollectionId { get; private set; }
    public Guid ArticleId { get; private set; }
    public DateTime AddedAt { get; private set; }
}

public static class CollectionErrors
{
    public static readonly Error NotFound = Error.NotFound("collection.not_found", "Collection not found.");
    public static readonly Error NameTaken = Error.Conflict("collection.name_taken", "You already have a collection with this name.");
    public static readonly Error LimitReached = Error.Validation("collection.limit", $"You can have at most {Collection.MaxPerUser} collections.");
}
