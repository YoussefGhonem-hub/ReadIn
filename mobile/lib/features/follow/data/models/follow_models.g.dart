// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowStateModel _$FollowStateModelFromJson(Map<String, dynamic> json) =>
    _FollowStateModel(
      isFollowing: json['isFollowing'] as bool,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FollowStateModelToJson(_FollowStateModel instance) =>
    <String, dynamic>{
      'isFollowing': instance.isFollowing,
      'followerCount': instance.followerCount,
    };

_UserSummaryModel _$UserSummaryModelFromJson(Map<String, dynamic> json) =>
    _UserSummaryModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      followsYou: json['followsYou'] as bool? ?? false,
    );

Map<String, dynamic> _$UserSummaryModelToJson(_UserSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'isVerified': instance.isVerified,
      'bio': ?instance.bio,
      'isFollowing': instance.isFollowing,
      'followsYou': instance.followsYou,
    };

_UserSummaryPageModel _$UserSummaryPageModelFromJson(
  Map<String, dynamic> json,
) => _UserSummaryPageModel(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => UserSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <UserSummaryModel>[],
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$UserSummaryPageModelToJson(
  _UserSummaryPageModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
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
