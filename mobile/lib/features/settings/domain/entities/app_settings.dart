import 'package:equatable/equatable.dart';

enum ThemePreference { system, light, dark }

/// Reader font size control S / M / L / XL (SPEC §11 F04).
enum ArticleFontSize { s, m, l, xl }

/// Local app preferences (SPEC §11 F18). Theme, languages and reminder time
/// are synced to the profile when signed in; the rest is device-only.
class AppSettings extends Equatable {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.uiLanguage = 'ar',
    this.articleLanguage = 'ar-EG',
    this.reminderTime = '08:00',
    this.fontSize = ArticleFontSize.m,
    this.welcomeSeen = false,
    this.dailyNotifications = true,
  });

  final ThemePreference theme;

  /// `ar` | `en`.
  final String uiLanguage;

  /// `ar-EG` | `en`.
  final String articleLanguage;

  /// `HH:mm`, user's local time.
  final String reminderTime;
  final ArticleFontSize fontSize;

  /// The onboarding welcome step was shown once (guests may skip sign-up).
  final bool welcomeSeen;
  final bool dailyNotifications;

  AppSettings copyWith({
    ThemePreference? theme,
    String? uiLanguage,
    String? articleLanguage,
    String? reminderTime,
    ArticleFontSize? fontSize,
    bool? welcomeSeen,
    bool? dailyNotifications,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        articleLanguage: articleLanguage ?? this.articleLanguage,
        reminderTime: reminderTime ?? this.reminderTime,
        fontSize: fontSize ?? this.fontSize,
        welcomeSeen: welcomeSeen ?? this.welcomeSeen,
        dailyNotifications: dailyNotifications ?? this.dailyNotifications,
      );

  /// True when a field that lives on the server profile differs.
  bool syncedFieldsDiffer(AppSettings other) =>
      theme != other.theme ||
      uiLanguage != other.uiLanguage ||
      articleLanguage != other.articleLanguage ||
      reminderTime != other.reminderTime;

  @override
  List<Object?> get props => [theme, uiLanguage, articleLanguage, reminderTime, fontSize, welcomeSeen, dailyNotifications];
}
