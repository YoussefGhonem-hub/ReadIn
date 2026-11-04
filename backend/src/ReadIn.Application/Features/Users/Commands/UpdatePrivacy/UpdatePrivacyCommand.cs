using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdatePrivacy;

/// <summary>
/// PUT /me/privacy — Settings → Privacy (SPEC F18). <see cref="PublicReadingStats"/> shows the reading stats card and
/// heatmap on the public profile (F14); <see cref="WhoCanMention"/> is who may @mention the user (F05, F11). Each one is
/// optional (left out = unchanged), but at least one is required.
/// </summary>
[Authenticated]
public sealed record UpdatePrivacyCommand(bool? PublicReadingStats, MentionPolicy? WhoCanMention = null) : ICommand<Result>;

internal sealed class UpdatePrivacyCommandValidator : AbstractValidator<UpdatePrivacyCommand>
{
    public UpdatePrivacyCommandValidator()
    {
        RuleFor(c => c.PublicReadingStats).NotNull().When(c => c.WhoCanMention is null);
        RuleFor(c => c.WhoCanMention).NotNull().When(c => c.PublicReadingStats is null);
        RuleFor(c => c.WhoCanMention).IsInEnum();
    }
}

internal sealed class UpdatePrivacyCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdatePrivacyCommand, Result>
{
    public async ValueTask<Result> Handle(UpdatePrivacyCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        user.SetPrivacy(command.PublicReadingStats, command.WhoCanMention);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
