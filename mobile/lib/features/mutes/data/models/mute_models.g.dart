// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mute_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserMuteStateModel _$UserMuteStateModelFromJson(Map<String, dynamic> json) =>
    _UserMuteStateModel(
      isMuted: json['isMuted'] as bool,
      isFollowing: json['isFollowing'] as bool? ?? false,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followRemoved: json['followRemoved'] as bool? ?? false,
    );

Map<String, dynamic> _$UserMuteStateModelToJson(_UserMuteStateModel instance) =>
    <String, dynamic>{
      'isMuted': instance.isMuted,
      'isFollowing': instance.isFollowing,
      'followerCount': instance.followerCount,
      'followRemoved': instance.followRemoved,
    };

_ContentMutesModel _$ContentMutesModelFromJson(
  Map<String, dynamic> json,
) => _ContentMutesModel(
  fieldIds:
      (json['fieldIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  topicIds:
      (json['topicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$ContentMutesModelToJson(_ContentMutesModel instance) =>
    <String, dynamic>{
      'fieldIds': instance.fieldIds,
      'topicIds': instance.topicIds,
    };

_MutedFieldModel _$MutedFieldModelFromJson(Map<String, dynamic> json) =>
    _MutedFieldModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
    );

Map<String, dynamic> _$MutedFieldModelToJson(_MutedFieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': ?instance.name,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'icon': instance.icon,
      'color': instance.color,
    };

_MutedTopicModel _$MutedTopicModelFromJson(Map<String, dynamic> json) =>
    _MutedTopicModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      field: MutedFieldModel.fromJson(json['field'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MutedTopicModelToJson(_MutedTopicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': ?instance.name,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'field': instance.field.toJson(),
    };

_MutesModel _$MutesModelFromJson(Map<String, dynamic> json) => _MutesModel(
  users:
      (json['users'] as List<dynamic>?)
          ?.map((e) => UserSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <UserSummaryModel>[],
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => MutedFieldModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MutedFieldModel>[],
  topics:
      (json['topics'] as List<dynamic>?)
          ?.map((e) => MutedTopicModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MutedTopicModel>[],
);

Map<String, dynamic> _$MutesModelToJson(_MutesModel instance) =>
    <String, dynamic>{
      'users': instance.users.map((e) => e.toJson()).toList(),
      'fields': instance.fields.map((e) => e.toJson()).toList(),
      'topics': instance.topics.map((e) => e.toJson()).toList(),
    };
