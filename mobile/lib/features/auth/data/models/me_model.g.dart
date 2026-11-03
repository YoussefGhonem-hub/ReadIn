// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeModel _$MeModelFromJson(Map<String, dynamic> json) => _MeModel(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  links:
      (json['links'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  uiLanguage: json['uiLanguage'] as String? ?? 'ar',
  articleLanguage: json['articleLanguage'] as String? ?? 'ar-EG',
  theme: json['theme'] as String? ?? 'system',
  timeZone: json['timeZone'] as String? ?? 'UTC',
  reminderTime: json['reminderTime'] as String? ?? '08:00',
  isVerified: json['isVerified'] as bool? ?? false,
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
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
);

Map<String, dynamic> _$MeModelToJson(_MeModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': ?instance.avatarUrl,
  'bio': ?instance.bio,
  'links': instance.links,
  'uiLanguage': instance.uiLanguage,
  'articleLanguage': instance.articleLanguage,
  'theme': instance.theme,
  'timeZone': instance.timeZone,
  'reminderTime': instance.reminderTime,
  'isVerified': instance.isVerified,
  'onboardingCompleted': instance.onboardingCompleted,
  'roles': instance.roles,
  'permissions': instance.permissions,
  'interests': instance.interests.toJson(),
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

_SyncUserRequest _$SyncUserRequestFromJson(Map<String, dynamic> json) =>
    _SyncUserRequest(
      uiLanguage: json['uiLanguage'] as String?,
      timeZone: json['timeZone'] as String?,
    );

Map<String, dynamic> _$SyncUserRequestToJson(_SyncUserRequest instance) =>
    <String, dynamic>{
      'uiLanguage': ?instance.uiLanguage,
      'timeZone': ?instance.timeZone,
    };
