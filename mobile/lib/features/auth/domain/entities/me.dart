import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/profile_link.dart';
import 'external_credential.dart';

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
    this.headline,
    this.links = const [],
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
    this.publicReadingStats = false,
    this.whoCanMention = MentionPolicy.everyone,
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

  /// The title under the name (F14); null when there is none.
  final String? headline;

  /// Social links (F14), in the member's order.
  final List<ProfileLink> links;
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

  /// `["Member"]` or `["SuperAdmin"]` (SPEC §10). Never gate on a role name: check [permissions] with [can], and
  /// the Verified badge with [isVerified].
  final List<String> roles;
  final List<String> permissions;
  final List<String> interestFieldIds;
  final List<String> interestTopicIds;

  /// `privacy.publicReadingStats`: other people see the reading stats card and heatmap on the profile (F14, F18).
  final bool publicReadingStats;

  /// `privacy.whoCanMention`: who may @mention me in comments and articles (F18).
  final MentionPolicy whoCanMention;

  /// `MeDto.privacy`, whole: what `PUT /me/privacy` takes back.
  PrivacySettings get privacy => PrivacySettings(publicReadingStats: publicReadingStats, whoCanMention: whoCanMention);

  bool can(String permission) => permissions.contains(permission);

  /// The linked Google / Apple sign-in of [provider], if any.
  ExternalLogin? externalLogin(ExternalProvider provider) =>
      externalLogins.where((login) => login.kind == provider).firstOrNull;

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
        headline,
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
        publicReadingStats,
        whoCanMention,
      ];
}

/// `privacy.whoCanMention` (F18): who may @mention me in comments and articles. Anyone else's `@me` stays plain text,
/// with no link and no notification.
enum MentionPolicy {
  everyone,

  /// People I follow.
  following,
  nobody;

  /// `everyone` | `following` | `nobody`.
  String get wire => name;

  /// [everyone], the default, when the API leaves it out (an older API) or sends a value this app version doesn't know.
  static MentionPolicy fromWire(Object? wire) => values.where((policy) => policy.wire == wire).firstOrNull ?? everyone;
}

/// `MeDto.privacy` (F14, F18). `PUT /me/privacy` gets it back whole.
class PrivacySettings extends Equatable {
  const PrivacySettings({this.publicReadingStats = false, this.whoCanMention = MentionPolicy.everyone});

  /// Other people see the reading stats card and heatmap on the profile (F14).
  final bool publicReadingStats;
  final MentionPolicy whoCanMention;

  PrivacySettings copyWith({bool? publicReadingStats, MentionPolicy? whoCanMention}) => PrivacySettings(
        publicReadingStats: publicReadingStats ?? this.publicReadingStats,
        whoCanMention: whoCanMention ?? this.whoCanMention,
      );

  @override
  List<Object?> get props => [publicReadingStats, whoCanMention];
}

/// A Google or Apple sign-in linked to the account (`MeDto.externalLogins`).
class ExternalLogin extends Equatable {
  const ExternalLogin({required this.provider, this.email, this.linkedAt});

  /// `google` or `apple`.
  final String provider;
  final String? email;
  final DateTime? linkedAt;

  /// Null for a provider this app version doesn't know.
  ExternalProvider? get kind => ExternalProvider.values.asNameMap()[provider];

  @override
  List<Object?> get props => [provider, email, linkedAt];
}
