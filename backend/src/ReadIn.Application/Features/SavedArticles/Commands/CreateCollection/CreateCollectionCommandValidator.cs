using FluentValidation;

namespace ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;

internal sealed class CreateCollectionCommandValidator : AbstractValidator<CreateCollectionCommand>
{
    public CreateCollectionCommandValidator() => RuleFor(c => c.Name).CollectionName();
}
