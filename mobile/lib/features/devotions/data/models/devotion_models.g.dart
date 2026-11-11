// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devotion_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PersonalDuaModel _$PersonalDuaModelFromJson(Map<String, dynamic> json) =>
    _PersonalDuaModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      repeat: (json['repeat'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PersonalDuaModelToJson(_PersonalDuaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': ?instance.title,
      'text': instance.text,
      'repeat': instance.repeat,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
