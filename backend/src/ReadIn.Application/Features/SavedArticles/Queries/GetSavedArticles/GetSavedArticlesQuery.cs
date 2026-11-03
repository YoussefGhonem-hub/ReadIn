using Mediator;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.SavedArticles.Queries.GetSavedArticles;

/// <summary>
/// GET /me/saved?field=&amp;q=&amp;collection= — your saved articles, newest saved first (SPEC F13).
/// <see cref="FieldSlug"/> keeps one field; <see cref="Search"/> matches titles in any language version, ignoring case,
/// Arabic diacritics and letter forms (SPEC §22); <see cref="CollectionId"/> keeps one of your collections. Articles
/// readers can no longer open are left out.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Saved.Manage)]
public sealed record GetSavedArticlesQuery(
    string? FieldSlug,
    string? Search,
    Guid? CollectionId,
    string? Cursor,
    int Limit,
    string UiLanguage) : IQuery<Result<CursorPage<SavedArticleDto>>>;
