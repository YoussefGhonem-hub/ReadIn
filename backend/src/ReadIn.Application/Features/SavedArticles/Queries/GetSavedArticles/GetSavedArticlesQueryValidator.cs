using FluentValidation;

namespace ReadIn.Application.Features.SavedArticles.Queries.GetSavedArticles;

internal sealed class GetSavedArticlesQueryValidator : AbstractValidator<GetSavedArticlesQuery>
{
    public const int MaxSearchLength = 100;

    public GetSavedArticlesQueryValidator() => RuleFor(q => q.Search).MaximumLength(MaxSearchLength).OverridePropertyName("q");
}
