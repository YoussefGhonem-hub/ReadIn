using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

public static class TaxonomyErrors
{
    public static readonly Error FieldNotFound = Error.NotFound("field.not_found", "Field not found.");
    public static readonly Error TopicNotFound = Error.NotFound("topic.not_found", "Topic not found.");

    /// <summary>An unknown or hidden tag (SPEC F32): its page and article list answer 404.</summary>
    public static readonly Error TagNotFound = Error.NotFound("tag.not_found", "Tag not found.");

    /// <summary>A new tag name that breaks the rules: 2–30 characters, letters, digits, spaces and <c>- _ . + #</c>.</summary>
    public static readonly Error TagInvalid = Error.Validation(
        "tag.invalid", "A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.");

    /// <summary>A publish would make the writer create more than 20 new tags in 24 hours (a <c>DraftProblemDto</c> code).</summary>
    public static readonly Error TagLimit = Error.Validation(
        "tag.limit", "You've created a lot of new tags today. Pick existing tags, or try again later.");

    /// <summary>A hidden tag the published article doesn't have already (a <c>DraftProblemDto</c> code).</summary>
    public static readonly Error TagHidden = Error.Validation("tag.hidden", "This tag isn't available. Choose another one.");
}
