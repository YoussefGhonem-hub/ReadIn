using FluentValidation;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions.Commands.SetReaction;

internal sealed class SetReactionCommandValidator : AbstractValidator<SetReactionCommand>
{
    public SetReactionCommandValidator() =>
        RuleFor(c => c.Type).Must(type => ReactionTypes.TryParse(type, out _)).WithErrorCode(ReactionValidation.InvalidCode);
}

internal static class ReactionValidation
{
    public const string InvalidCode = "reaction.invalid";
}
