using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.Glossary;

/// <summary>A glossary term with the published articles that use it (SPEC F21).</summary>
public sealed record GlossaryTermDto(
    string Slug,
    string Term,
    string DefinitionEn,
    string ExplanationAr,
    IReadOnlyList<GlossaryArticleDto> Articles);

/// <summary>An article that uses a term; <see cref="Language"/> is the language of <see cref="Title"/>.</summary>
public sealed record GlossaryArticleDto(Guid Id, string Slug, string Language, string Title, int ReadingTimeMinutes, FieldRefDto Field);

public sealed record GlossaryTermSummaryDto(string Slug, string Term, string DefinitionEn);
