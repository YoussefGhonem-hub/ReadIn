import 'package:equatable/equatable.dart';

/// The signed-in user as stored in SQL Server (`MeDto`, docs/api/contract-v1.md).
class Me extends Equatable {
  const Me({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.links = const {},
    this.uiLanguage = 'ar',
    this.articleLanguage = 'ar-EG',
    this.theme = 'system',
    this.timeZone = 'UTC',
    this.reminderTime = '08:00',
    this.isVerified = false,
    this.onboardingCompleted = false,
    this.roles = const [],
    this.permissions = const [],
    this.interestFieldIds = const [],
    this.interestTopicIds = const [],
  });

  final String id;
  final String email;
  final String displayName;

  /// `@handle` without the `@`.
  final String username;
  final String? avatarUrl;
  final String? bio;
  final Map<String, String> links;
  final String uiLanguage;
  final String articleLanguage;
  final String theme;
  final String timeZone;
  final String reminderTime;
  final bool isVerified;
  final bool onboardingCompleted;
  final List<String> roles;
  final List<String> permissions;
  final List<String> interestFieldIds;
  final List<String> interestTopicIds;

  bool can(String permission) => permissions.contains(permission);

  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        username,
        avatarUrl,
        bio,
        links,
        uiLanguage,
        articleLanguage,
        theme,
        timeZone,
        reminderTime,
        isVerified,
        onboardingCompleted,
        roles,
        permissions,
        interestFieldIds,
        interestTopicIds,
      ];
}
