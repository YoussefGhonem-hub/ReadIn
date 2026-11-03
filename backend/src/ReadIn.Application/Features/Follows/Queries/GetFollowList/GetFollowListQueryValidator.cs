using FluentValidation;

namespace ReadIn.Application.Features.Follows.Queries.GetFollowList;

internal sealed class GetFollowListQueryValidator : AbstractValidator<GetFollowListQuery>
{
    public GetFollowListQueryValidator() => RuleFor(q => q.Search).MaximumLength(100).OverridePropertyName("q");
}
