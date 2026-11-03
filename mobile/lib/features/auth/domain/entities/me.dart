import 'package:equatable/equatable.dart';

/// The signed-in user as stored in SQL Server (`MeDto`, docs/api/contract-v1.md).
class Me extends Equatable {
  const Me({
    required this.id,
    required this.displayName,
    required this.username,
    this.phoneNumber,
    this.email,
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
    this.mustChangePassword = false,
    this.mustSetRecoveryPin = false,
    this.isProfileComplete = true,
    this.hasRecoveryPin = true,
    this.hasPassword = true,
    this.externalLogins = const [],
    this.roles = const [],
    this.permissions = const [],
    this.interestFieldIds = const [],
    this.interestTopicIds = const [],
  });

  final String id;

  /// E.164, shown only to its owner (SPEC §9.5).
  final String? phoneNumber;
  final String? email;
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

  /// Account guards, applied in this order after sign in and on app start (SPEC §9.2).
  final bool mustChangePassword;
  final bool mustSetRecoveryPin;
  final bool isProfileComplete;
  final bool hasRecoveryPin;

  /// False for an account created with Google or Apple that never set a password.
  final bool hasPassword;

  /// Google / Apple sign-ins linked to this account.
  final List<ExternalLogin> externalLogins;

  final List<String> roles;
  final List<String> permissions;
  final List<String> interestFieldIds;
  final List<String> interestTopicIds;

  bool can(String permission) => permissions.contains(permission);

  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
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
        mustChangePassword,
        mustSetRecoveryPin,
        isProfileComplete,
        hasRecoveryPin,
        hasPassword,
        externalLogins,
        roles,
        permissions,
        interestFieldIds,
        interestTopicIds,
      ];
}

/// A Google or Apple sign-in linked to the account (`MeDto.externalLogins`).
class ExternalLogin extends Equatable {
  const ExternalLogin({required this.provider, this.email, this.linkedAt});

  /// `google` or `apple`.
  final String provider;
  final String? email;
  final DateTime? linkedAt;

  @override
  List<Object?> get props => [provider, email, linkedAt];
}
