// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_preferences_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdatePreferencesRequest _$UpdatePreferencesRequestFromJson(
  Map<String, dynamic> json,
) => _UpdatePreferencesRequest(
  uiLanguage: json['uiLanguage'] as String,
  articleLanguage: json['articleLanguage'] as String,
  theme: json['theme'] as String,
  timeZone: json['timeZone'] as String,
  reminderTime: json['reminderTime'] as String,
  showHighlights: json['showHighlights'] as bool?,
);

Map<String, dynamic> _$UpdatePreferencesRequestToJson(
  _UpdatePreferencesRequest instance,
) => <String, dynamic>{
  'uiLanguage': instance.uiLanguage,
  'articleLanguage': instance.articleLanguage,
  'theme': instance.theme,
  'timeZone': instance.timeZone,
  'reminderTime': instance.reminderTime,
  'showHighlights': ?instance.showHighlights,
};
