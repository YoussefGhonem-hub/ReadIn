using ReadIn.Domain.Common;

namespace ReadIn.Domain.Taxonomy;

public static class TaxonomyErrors
{
    public static readonly Error FieldNotFound = Error.NotFound("field.not_found", "Field not found.");
    public static readonly Error TopicNotFound = Error.NotFound("topic.not_found", "Topic not found.");
}
