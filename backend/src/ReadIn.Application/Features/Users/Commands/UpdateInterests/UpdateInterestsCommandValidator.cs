using FluentValidation;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdateInterests;

internal sealed class UpdateInterestsCommandValidator : AbstractValidator<UpdateInterestsCommand>
{
    public UpdateInterestsCommandValidator()
    {
        RuleFor(c => c.FieldIds).NotNull();
        RuleFor(c => c.TopicIds).NotNull();
        RuleFor(c => c)
            .Must(c => (c.FieldIds?.Distinct().Count() ?? 0) + (c.TopicIds?.Distinct().Count() ?? 0) >= User.MinInterests)
            .WithName("interests")
            .OverridePropertyName("interests")
            .WithErrorCode("user.interests.min_three");
        RuleFor(c => c)
            .Must(c => (c.FieldIds?.Count ?? 0) + (c.TopicIds?.Count ?? 0) <= 100)
            .OverridePropertyName("interests")
            .WithErrorCode("validation.max_length");
    }
}
