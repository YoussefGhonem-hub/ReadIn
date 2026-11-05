// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeModel _$MeModelFromJson(Map<String, dynamic> json) => _MeModel(
  id: json['id'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  email: json['email'] as String?,
  displayName: json['displayName'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  headline: json['headline'] as String?,
  links: json['links'] == null
      ? const <ProfileLinkModel>[]
      : const ProfileLinksJson().fromJson(json['links']),
  uiLanguage: json['uiLanguage'] as String? ?? 'ar',
  articleLanguage: json['articleLanguage'] as String? ?? 'ar-EG',
  theme: json['theme'] as String? ?? 'system',
  timeZone: json['timeZone'] as String? ?? 'UTC',
  reminderTime: json['reminderTime'] as String? ?? '08:00',
  isVerified: json['isVerified'] as bool? ?? false,
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  mustSetRecoveryPin: json['mustSetRecoveryPin'] as bool? ?? false,
  isProfileComplete: json['isProfileComplete'] as bool? ?? true,
  hasRecoveryPin: json['hasRecoveryPin'] as bool? ?? true,
  hasPassword: json['hasPassword'] as bool? ?? true,
  externalLogins:
      (json['externalLogins'] as List<dynamic>?)
          ?.map((e) => ExternalLoginModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ExternalLoginModel>[],
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  interests: json['interests'] == null
      ? const InterestsModel()
      : InterestsModel.fromJson(json['interests'] as Map<String, dynamic>),
  privacy: json['privacy'] == null
      ? const PrivacyModel()
      : PrivacyModel.fromJson(json['privacy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MeModelToJson(_MeModel instance) => <String, dynamic>{
  'id': instance.id,
  'phoneNumber': ?instance.phoneNumber,
  'email': ?instance.email,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': ?instance.avatarUrl,
  'bio': ?instance.bio,
  'headline': ?instance.headline,
  'links': ?const ProfileLinksJson().toJson(instance.links),
  'uiLanguage': instance.uiLanguage,
  'articleLanguage': instance.articleLanguage,
  'theme': instance.theme,
  'timeZone': instance.timeZone,
  'reminderTime': instance.reminderTime,
  'isVerified': instance.isVerified,
  'onboardingCompleted': instance.onboardingCompleted,
  'mustChangePassword': instance.mustChangePassword,
  'mustSetRecoveryPin': instance.mustSetRecoveryPin,
  'isProfileComplete': instance.isProfileComplete,
  'hasRecoveryPin': instance.hasRecoveryPin,
  'hasPassword': instance.hasPassword,
  'externalLogins': instance.externalLogins.map((e) => e.toJson()).toList(),
  'roles': instance.roles,
  'permissions': instance.permissions,
  'interests': instance.interests.toJson(),
  'privacy': instance.privacy.toJson(),
};

_ExternalLoginModel _$ExternalLoginModelFromJson(Map<String, dynamic> json) =>
    _ExternalLoginModel(
      provider: json['provider'] as String,
      email: json['email'] as String?,
      linkedAt: json['linkedAt'] == null
          ? null
          : DateTime.parse(json['linkedAt'] as String),
    );

Map<String, dynamic> _$ExternalLoginModelToJson(_ExternalLoginModel instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'email': ?instance.email,
      'linkedAt': ?instance.linkedAt?.toIso8601String(),
    };

_InterestsModel _$InterestsModelFromJson(
  Map<String, dynamic> json,
) => _InterestsModel(
  fieldIds:
      (json['fieldIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  topicIds:
      (json['topicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$InterestsModelToJson(_InterestsModel instance) =>
    <String, dynamic>{
      'fieldIds': instance.fieldIds,
      'topicIds': instance.topicIds,
    };

_PrivacyModel _$PrivacyModelFromJson(Map<String, dynamic> json) =>
    _PrivacyModel(
      publicReadingStats: json['publicReadingStats'] as bool? ?? false,
      whoCanMention: json['whoCanMention'] as String?,
    );

Map<String, dynamic> _$PrivacyModelToJson(_PrivacyModel instance) =>
    <String, dynamic>{
      'publicReadingStats': instance.publicReadingStats,
      'whoCanMention': ?instance.whoCanMention,
    };

_SessionModel _$SessionModelFromJson(Map<String, dynamic> json) =>
    _SessionModel(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ),
      user: MeModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SessionModelToJson(_SessionModel instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'accessTokenExpiresAt': instance.accessTokenExpiresAt.toIso8601String(),
      'refreshToken': ?instance.refreshToken,
      'refreshTokenExpiresAt': instance.refreshTokenExpiresAt.toIso8601String(),
      'user': instance.user.toJson(),
    };

_AuthConfigModel _$AuthConfigModelFromJson(
  Map<String, dynamic> json,
) => _AuthConfigModel(
  pinLength:
      (json['pinLength'] as num?)?.toInt() ?? RecoveryPinRules.defaultLength,
  password: json['password'] == null
      ? const PasswordRulesModel()
      : PasswordRulesModel.fromJson(json['password'] as Map<String, dynamic>),
  externalProviders:
      (json['externalProviders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$AuthConfigModelToJson(_AuthConfigModel instance) =>
    <String, dynamic>{
      'pinLength': instance.pinLength,
      'password': instance.password.toJson(),
      'externalProviders': instance.externalProviders,
    };

_PasswordRulesModel _$PasswordRulesModelFromJson(Map<String, dynamic> json) =>
    _PasswordRulesModel(
      minLength: (json['minLength'] as num?)?.toInt() ?? 8,
      maxLength: (json['maxLength'] as num?)?.toInt() ?? 128,
      requireLetter: json['requireLetter'] as bool? ?? true,
      requireDigit: json['requireDigit'] as bool? ?? true,
    );

Map<String, dynamic> _$PasswordRulesModelToJson(_PasswordRulesModel instance) =>
    <String, dynamic>{
      'minLength': instance.minLength,
      'maxLength': instance.maxLength,
      'requireLetter': instance.requireLetter,
      'requireDigit': instance.requireDigit,
    };

_ResetTokenModel _$ResetTokenModelFromJson(Map<String, dynamic> json) =>
    _ResetTokenModel(
      resetToken: json['resetToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$ResetTokenModelToJson(_ResetTokenModel instance) =>
    <String, dynamic>{
      'resetToken': instance.resetToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_UsernameAvailabilityModel _$UsernameAvailabilityModelFromJson(
  Map<String, dynamic> json,
) => _UsernameAvailabilityModel(
  username: json['username'] as String,
  valid: json['valid'] as bool,
  available: json['available'] as bool,
);

Map<String, dynamic> _$UsernameAvailabilityModelToJson(
  _UsernameAvailabilityModel instance,
) => <String, dynamic>{
  'username': instance.username,
  'valid': instance.valid,
  'available': instance.available,
};
