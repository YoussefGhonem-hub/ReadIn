using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>Editor (F05) error codes beyond <see cref="Domain.Articles.ArticleErrors"/>; clients translate them.</summary>
public static class EditorErrors
{
    public static class Codes
    {
        public const string FieldRequired = "article.field_required";
        public const string TitleLength = "article.title_length";
        public const string ContentEmpty = "article.content_empty";
        public const string ContentInvalid = "article.content_invalid";
        public const string ImageAltRequired = "article.image_alt_required";
    }

    public static readonly Error FieldNotFound = Error.Validation("field.not_found", "Field not found.");
    public static readonly Error StatusInvalid = Error.Validation("article.status_invalid", "Status must be draft or published.");
    public static readonly Error TopicNotInField = Error.Validation("topic.not_in_field", "The topic does not belong to this field.");

    /// <summary>Publishing an article with problems: the first problem's code, all of them in <c>problems</c>.</summary>
    public static Error NotReady(IReadOnlyList<DraftProblemDto> problems) =>
        Error.Validation(problems[0].Code, "The article is not ready to publish.") with
        {
            Extensions = new Dictionary<string, object?> { ["problems"] = problems },
        };
}
