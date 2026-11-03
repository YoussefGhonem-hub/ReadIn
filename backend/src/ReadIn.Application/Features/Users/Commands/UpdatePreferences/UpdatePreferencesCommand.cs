using Mediator;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Users.Commands.UpdatePreferences;

/// <summary>PUT /me/preferences — theme is synced across devices (SPEC F18, §15.5).</summary>
[Authenticated]
public sealed record UpdatePreferencesCommand(
    string UiLanguage,
    string ArticleLanguage,
    ThemePreference Theme,
    string TimeZone,
    string ReminderTime) : ICommand<Result>;
