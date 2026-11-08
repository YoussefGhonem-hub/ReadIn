// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserBlockStateModel _$UserBlockStateModelFromJson(Map<String, dynamic> json) =>
    _UserBlockStateModel(
      userId: json['userId'] as String,
      isBlocked: json['isBlocked'] as bool,
      followRemoved: json['followRemoved'] as bool? ?? false,
    );

Map<String, dynamic> _$UserBlockStateModelToJson(
  _UserBlockStateModel instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'isBlocked': instance.isBlocked,
  'followRemoved': instance.followRemoved,
};

_BlockedUserModel _$BlockedUserModelFromJson(Map<String, dynamic> json) =>
    _BlockedUserModel(
      user: UserSummaryModel.fromJson(json['user'] as Map<String, dynamic>),
      blockedAt: DateTime.parse(json['blockedAt'] as String),
    );

Map<String, dynamic> _$BlockedUserModelToJson(_BlockedUserModel instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'blockedAt': instance.blockedAt.toIso8601String(),
    };

_BlockedUsersModel _$BlockedUsersModelFromJson(Map<String, dynamic> json) =>
    _BlockedUsersModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => BlockedUserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BlockedUserModel>[],
    );

Map<String, dynamic> _$BlockedUsersModelToJson(_BlockedUsersModel instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
