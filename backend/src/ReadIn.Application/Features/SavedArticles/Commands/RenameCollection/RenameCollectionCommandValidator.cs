using FluentValidation;

namespace ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;

internal sealed class RenameCollectionCommandValidator : AbstractValidator<RenameCollectionCommand>
{
    public RenameCollectionCommandValidator() => RuleFor(c => c.Name).CollectionName();
}
