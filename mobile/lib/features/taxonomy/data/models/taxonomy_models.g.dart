// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taxonomy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FieldModel _$FieldModelFromJson(Map<String, dynamic> json) => _FieldModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  name: json['name'] as String?,
  icon: json['icon'] as String? ?? 'book-open',
  color: json['color'] as String? ?? 'primary',
  isSensitive: json['isSensitive'] as bool? ?? false,
  requiresSources: json['requiresSources'] as bool? ?? false,
  topicCount: (json['topicCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FieldModelToJson(_FieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'name': ?instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isSensitive': instance.isSensitive,
      'requiresSources': instance.requiresSources,
      'topicCount': instance.topicCount,
    };

_TopicModel _$TopicModelFromJson(Map<String, dynamic> json) => _TopicModel(
  id: json['id'] as String,
  fieldId: json['fieldId'] as String,
  slug: json['slug'] as String,
  nameAr: json['nameAr'] as String,
  nameEn: json['nameEn'] as String,
  name: json['name'] as String?,
);

Map<String, dynamic> _$TopicModelToJson(_TopicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fieldId': instance.fieldId,
      'slug': instance.slug,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'name': ?instance.name,
    };
