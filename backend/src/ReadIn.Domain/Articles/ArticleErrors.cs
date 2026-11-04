using ReadIn.Domain.Common;

namespace ReadIn.Domain.Articles;

public static class ArticleErrors
{
    public static readonly Error NotFound = Error.NotFound("article.not_found", "Article not found.");
    public static readonly Error InvalidLanguage = Error.Validation("article.language_invalid", "Article language must be ar-EG or en.");
    public static readonly Error TranslationExists = Error.Conflict("article.translation_exists", "This language version already exists.");
    public static readonly Error TranslationNotFound = Error.NotFound("article.translation_not_found", "This language version does not exist.");
    public static readonly Error TooManyTags = Error.Validation("article.tags.max_five", "An article can have at most 5 tags.");
    public static readonly Error NoContent = Error.Validation("article.no_content", "Add at least one language version first.");
    public static readonly Error SourcesRequired = Error.Validation("article.sources_required", "Articles in this field must cite at least one source.");
    public static readonly Error NotOwner = Error.Forbidden("article.not_owner", "Only the author can change this article.");
    public static readonly Error SlugTaken = Error.Conflict("article.slug_taken", "An article with this slug already exists.");
    public static readonly Error DraftConflict = Error.Conflict("article.draft_conflict", "The draft was changed on another device. Reload it or keep your version.");
    public static readonly Error NotPublished = Error.Conflict("article.not_published", "Only a published article has changes to discard.");
    public static readonly Error RevisionNotFound = Error.NotFound("article.revision_not_found", "Revision not found.");
    public static readonly Error InvalidContent = Error.Validation("article.content_invalid", "The article content is not valid RDoc.");

    public static Error InvalidTransition(ArticleStatus from, ArticleStatus to) =>
        Error.Conflict("article.invalid_transition", $"Cannot move an article from {from} to {to}.");
}
