using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.WriterCategories;

/// <summary>
/// A writer's category (SPEC F31, <c>docs/api/contract-v1.md</c> "Writer categories"): a card of the profile's
/// Categories tab and a row of the writer's manage list. <see cref="Slug"/> is made once from the name and never changes
/// on rename (only a moderator's clear changes it).
/// </summary>
/// <param name="Name">1–40 characters, the writer's spelling; clients show it with <c>dir="auto"</c>.</param>
/// <param name="ArticleCount">Articles readers can see in it, the same for everyone; 0 only in <c>GET /me/categories</c>.</param>
/// <param name="SortOrder">The writer's order, ascending (1..N in <c>GET /me/categories</c>).</param>
public sealed record WriterCategoryDto(Guid Id, string Slug, string Name, int ArticleCount, int SortOrder);

/// <summary>
/// <c>GET /users/{username}/categories</c> (the categories with articles readers can see), <c>GET /me/categories</c> and
/// <c>PUT /me/categories/order</c> (all of the writer's, empty ones included), in the writer's order.
/// </summary>
/// <param name="UncategorizedCount">
/// The writer's articles readers can see that have no category: the last card, "مقالات تانية" (slug
/// <see cref="WriterCategoryLimits.OtherSlug"/>); clients hide it when 0.
/// </param>
public sealed record WriterCategoryListDto(IReadOnlyList<WriterCategoryDto> Items, int UncategorizedCount);

/// <summary>
/// <c>GET /users/{username}/categories/{slug}</c>: the category page's header. For the uncategorized list
/// (<see cref="WriterCategoryLimits.OtherSlug"/>) <see cref="Id"/> and <see cref="Name"/> are null and clients show
/// "مقالات تانية" / "Other articles".
/// </summary>
/// <param name="ArticleCount">Articles readers can see in it; 0 is the empty state (web: <c>noindex</c>).</param>
/// <param name="Author">The writer, for the page title and the link back to the profile.</param>
public sealed record WriterCategoryPageDto(Guid? Id, string Slug, string? Name, int ArticleCount, AuthorDto Author);

/// <summary>The sizes and names the contract promises (SPEC F31).</summary>
public static class WriterCategoryLimits
{
    /// <summary>Categories one writer may have (<c>category.limit</c>).</summary>
    public const int MaxPerWriter = 50;

    /// <summary>A name has 1–40 characters (UTF-16 code units) after cleaning (<c>category.name_invalid</c>).</summary>
    public const int MinNameLength = 1;
    public const int MaxNameLength = 40;

    /// <summary>
    /// The reserved slug of the uncategorized list ("مقالات تانية"). A category's slug never starts with <c>_</c>, so it
    /// can't clash.
    /// </summary>
    public const string OtherSlug = "_other";

    /// <summary><c>limit</c> of a category page's articles: 1–50, default 20.</summary>
    public const int DefaultLimit = 20;
    public const int MaxLimit = 50;
}
