using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdatePreferences;

internal sealed class UpdatePreferencesCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<UpdatePreferencesCommand, Result>
{
    public async ValueTask<Result> Handle(UpdatePreferencesCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, cancellationToken);

        UpdatePreferencesCommandValidator.TryParseTime(command.ReminderTime, out var reminder);
        var result = user.SetPreferences(command.UiLanguage, command.ArticleLanguage, command.Theme, command.TimeZone, reminder);
        if (result.IsFailure) return result;
        if (command.ShowHighlights is { } showHighlights) user.SetShowHighlights(showHighlights);

        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
