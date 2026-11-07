// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_policy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlatformUpdatePolicyModel _$PlatformUpdatePolicyModelFromJson(
  Map<String, dynamic> json,
) => _PlatformUpdatePolicyModel(
  minimumVersion: json['minimumVersion'] as String?,
  storeUrl: json['storeUrl'] as String?,
);

Map<String, dynamic> _$PlatformUpdatePolicyModelToJson(
  _PlatformUpdatePolicyModel instance,
) => <String, dynamic>{
  'minimumVersion': ?instance.minimumVersion,
  'storeUrl': ?instance.storeUrl,
};

_UpdatePolicyModel _$UpdatePolicyModelFromJson(Map<String, dynamic> json) =>
    _UpdatePolicyModel(
      ios: json['ios'] == null
          ? null
          : PlatformUpdatePolicyModel.fromJson(
              json['ios'] as Map<String, dynamic>,
            ),
      android: json['android'] == null
          ? null
          : PlatformUpdatePolicyModel.fromJson(
              json['android'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$UpdatePolicyModelToJson(_UpdatePolicyModel instance) =>
    <String, dynamic>{
      'ios': ?instance.ios?.toJson(),
      'android': ?instance.android?.toJson(),
    };
