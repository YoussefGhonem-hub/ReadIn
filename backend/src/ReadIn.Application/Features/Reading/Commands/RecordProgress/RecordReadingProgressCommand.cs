using FluentValidation;
using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reading.Commands.RecordProgress;

/// <summary>
/// PUT /articles/{id}/progress (SPEC F04, F08). The reader reports its scroll percent, position and the active seconds
/// since its previous report. The first report of an article credits no time, so readers send one when they open it.
/// </summary>
[Authenticated]
public sealed record RecordReadingProgressCommand(
    Guid ArticleId,
    string Language,
    int Percent,
    string? LastPosition,
    int ActiveSecondsDelta) : ICommand<Result<ReadingProgressResultDto>>;

internal sealed class RecordReadingProgressCommandValidator : AbstractValidator<RecordReadingProgressCommand>
{
    public RecordReadingProgressCommandValidator()
    {
        RuleFor(c => c.Language).Must(ArticleLanguages.IsValid).WithErrorCode("article.language_invalid");
        RuleFor(c => c.Percent).InclusiveBetween(0, 100);
        RuleFor(c => c.LastPosition).MaximumLength(100);
        RuleFor(c => c.ActiveSecondsDelta).InclusiveBetween(0, 3600);
    }
}
