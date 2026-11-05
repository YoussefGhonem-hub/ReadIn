using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdatePreferences;

/// <summary>PUT /me/preferences — theme is synced across devices (SPEC F18, §15.5).</summary>
/// <param name="ShowHighlights">Show highlight marks in the reader (F30). Omitted (null) keeps the current setting.</param>
[Authenticated]
public sealed record UpdatePreferencesCommand(
    string UiLanguage,
    string ArticleLanguage,
    ThemePreference Theme,
    string TimeZone,
    string ReminderTime,
    bool? ShowHighlights = null) : ICommand<Result>;
