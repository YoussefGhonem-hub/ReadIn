using FluentValidation;
using ReadIn.Application.Features.Reactions.Commands.SetReaction;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;

internal sealed class GetArticleReactorsQueryValidator : AbstractValidator<GetArticleReactorsQuery>
{
    public GetArticleReactorsQueryValidator() =>
        RuleFor(q => q.Type)
            .Must(type => ReactionTypes.TryParse(type, out _))
            .When(q => !string.IsNullOrEmpty(q.Type))
            .WithErrorCode(ReactionValidation.InvalidCode);
}
