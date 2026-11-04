using ReadIn.Domain.Common;

namespace ReadIn.Domain.Glossary;

/// <summary>
/// A term of the central glossary (SPEC F21), e.g. "Dependency Injection". Terms come from content/glossary/*.yaml;
/// <see cref="Slug"/> is the <c>termId</c> of RDoc <c>term</c> nodes, so readers can tap a term to see its definition.
/// </summary>
public sealed class GlossaryTerm : Entity
{
    public const int SlugMaxLength = 100;
    public const int TermMaxLength = 200;
    public const int DefinitionMaxLength = 2000;

    private GlossaryTerm() { } // EF

    public GlossaryTerm(string slug, string termEn, string definitionEn, string explanationAr)
    {
        Slug = slug;
        TermEn = termEn;
        DefinitionEn = definitionEn;
        ExplanationAr = explanationAr;
    }

    public string Slug { get; private set; } = default!;
    public string TermEn { get; private set; } = default!;
    public string DefinitionEn { get; private set; } = default!;

    /// <summary>Egyptian Arabic with English terms, like ar-EG articles (SPEC §14.3).</summary>
    public string ExplanationAr { get; private set; } = default!;

    public void Update(string termEn, string definitionEn, string explanationAr)
    {
        TermEn = termEn;
        DefinitionEn = definitionEn;
        ExplanationAr = explanationAr;
    }
}

/// <summary>
/// An article that uses a glossary term in any of its versions. A derived index of the published content, rebuilt from
/// the RDoc <c>term</c> nodes; it powers "articles that use this term" and related articles.
/// </summary>
public sealed class ArticleTerm
{
    private ArticleTerm() { } // EF

    public ArticleTerm(Guid articleId, Guid termId)
    {
        ArticleId = articleId;
        TermId = termId;
    }

    public Guid ArticleId { get; private set; }
    public Guid TermId { get; private set; }
}

public static class GlossaryErrors
{
    public static readonly Error TermNotFound = Error.NotFound("glossary.term_not_found", "This term isn't in the glossary.");
}
