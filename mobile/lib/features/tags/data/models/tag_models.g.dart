// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagRefModel _$TagRefModelFromJson(Map<String, dynamic> json) => _TagRefModel(
  slug: json['slug'] as String? ?? '',
  name: json['name'] as String,
);

Map<String, dynamic> _$TagRefModelToJson(_TagRefModel instance) =>
    <String, dynamic>{'slug': instance.slug, 'name': instance.name};

_TagModel _$TagModelFromJson(Map<String, dynamic> json) => _TagModel(
  slug: json['slug'] as String,
  name: json['name'] as String,
  articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TagModelToJson(_TagModel instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'articleCount': instance.articleCount,
};
