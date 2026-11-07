namespace ReadIn.Application.Features.Admin.Tags;

/// <summary>A row of GET /admin/tags, and the answer of every tag write (SPEC F23).</summary>
public sealed record AdminTagDto(
    Guid Id,
    string Slug,
    string Name,
    int ArticleCount,
    int TaggedCount,
    bool IsHidden,
    bool IsSystem,
    DateTime CreatedAt,
    AdminTagCreatorDto? CreatedBy,
    DateTime? EmptySince,
    IReadOnlyList<string> Aliases);

/// <summary>The writer whose publish created the tag; null for a system tag or a deleted account.</summary>
public sealed record AdminTagCreatorDto(Guid Id, string Username);

/// <summary>Body of PUT /admin/tags/{id} (rename).</summary>
public sealed record RenameTagRequest(string? Name);

/// <summary>Body of POST /admin/tags/{id}/merge.</summary>
public sealed record MergeTagRequest(Guid IntoTagId);

/// <summary>
/// A merge's effect on one article's tags (SPEC F23): the merged tag's place goes to the tag it went into, and an article
/// that had both keeps that tag once, at the first of the two places. The other tags keep their order, and the article
/// never gains a tag, so the 5-tag limit holds.
/// </summary>
public static class TagMerge
{
    /// <param name="ordered">The article's tag ids in the writer's order.</param>
    public static IReadOnlyList<Guid> Replace(IReadOnlyList<Guid> ordered, Guid from, Guid into)
    {
        var result = new List<Guid>(ordered.Count);
        foreach (var id in ordered)
        {
            var next = id == from ? into : id;
            if (!result.Contains(next)) result.Add(next);
        }
        return result;
    }
}
