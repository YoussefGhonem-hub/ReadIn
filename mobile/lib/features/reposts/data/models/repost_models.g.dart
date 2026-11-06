// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repost_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RepostRequest _$RepostRequestFromJson(Map<String, dynamic> json) =>
    _RepostRequest(caption: json['caption'] as String?);

Map<String, dynamic> _$RepostRequestToJson(_RepostRequest instance) =>
    <String, dynamic>{'caption': ?instance.caption};

_RepostStateModel _$RepostStateModelFromJson(Map<String, dynamic> json) =>
    _RepostStateModel(
      repostCount: (json['repostCount'] as num?)?.toInt() ?? 0,
      isReposted: json['isReposted'] as bool? ?? false,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$RepostStateModelToJson(_RepostStateModel instance) =>
    <String, dynamic>{
      'repostCount': instance.repostCount,
      'isReposted': instance.isReposted,
      'caption': ?instance.caption,
    };
