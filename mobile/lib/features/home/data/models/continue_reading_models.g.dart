// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continue_reading_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContinueReadingModel _$ContinueReadingModelFromJson(
  Map<String, dynamic> json,
) => _ContinueReadingModel(
  article: ArticleCardModel.fromJson(json['article'] as Map<String, dynamic>),
  percent: (json['percent'] as num?)?.toInt() ?? 0,
  language: json['language'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ContinueReadingModelToJson(
  _ContinueReadingModel instance,
) => <String, dynamic>{
  'article': instance.article.toJson(),
  'percent': instance.percent,
  'language': instance.language,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
