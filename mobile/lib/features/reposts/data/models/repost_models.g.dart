// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repost_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RepostStateModel _$RepostStateModelFromJson(Map<String, dynamic> json) =>
    _RepostStateModel(
      repostCount: (json['repostCount'] as num?)?.toInt() ?? 0,
      isReposted: json['isReposted'] as bool? ?? false,
    );

Map<String, dynamic> _$RepostStateModelToJson(_RepostStateModel instance) =>
    <String, dynamic>{
      'repostCount': instance.repostCount,
      'isReposted': instance.isReposted,
    };
