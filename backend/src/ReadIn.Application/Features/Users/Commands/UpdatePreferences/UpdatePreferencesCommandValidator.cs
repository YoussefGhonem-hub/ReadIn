using System.Globalization;
using FluentValidation;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdatePreferences;

internal sealed class UpdatePreferencesCommandValidator : AbstractValidator<UpdatePreferencesCommand>
{
    public UpdatePreferencesCommandValidator()
    {
        RuleFor(c => c.UiLanguage).Must(UiLanguages.IsValid).WithErrorCode("user.language_invalid");
        RuleFor(c => c.ArticleLanguage).Must(ArticleLanguages.IsValid).WithErrorCode("user.language_invalid");
        RuleFor(c => c.Theme).IsInEnum();
        RuleFor(c => c.TimeZone)
            .Must(tz => !string.IsNullOrWhiteSpace(tz) && TimeZoneInfo.TryFindSystemTimeZoneById(tz, out _))
            .WithErrorCode("user.timezone_invalid");
        RuleFor(c => c.ReminderTime)
            .Must(t => TryParseTime(t, out _))
            .WithErrorCode("user.reminder_time_invalid");
    }

    internal static bool TryParseTime(string? value, out TimeOnly time) =>
        TimeOnly.TryParseExact(value, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out time);
}
