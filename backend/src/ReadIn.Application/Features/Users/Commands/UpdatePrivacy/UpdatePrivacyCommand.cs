using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdatePrivacy;

/// <summary>
/// PUT /me/privacy — Settings → Privacy (SPEC F18). <see cref="PublicReadingStats"/> shows the reading stats card and
/// heatmap on the public profile (F14). "Who can mention me" joins it with F11.
/// </summary>
[Authenticated]
public sealed record UpdatePrivacyCommand(bool? PublicReadingStats) : ICommand<Result>;

internal sealed class UpdatePrivacyCommandValidator : AbstractValidator<UpdatePrivacyCommand>
{
    public UpdatePrivacyCommandValidator() => RuleFor(c => c.PublicReadingStats).NotNull();
}

internal sealed class UpdatePrivacyCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdatePrivacyCommand, Result>
{
    public async ValueTask<Result> Handle(UpdatePrivacyCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        user.SetPrivacy(command.PublicReadingStats!.Value);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
