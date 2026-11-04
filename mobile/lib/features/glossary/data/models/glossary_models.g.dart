// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GlossaryArticleModel _$GlossaryArticleModelFromJson(
  Map<String, dynamic> json,
) => _GlossaryArticleModel(
  id: json['id'] as String,
  slug: json['slug'] as String,
  language: json['language'] as String,
  title: json['title'] as String,
  readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 1,
  field: FieldRefModel.fromJson(json['field'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GlossaryArticleModelToJson(
  _GlossaryArticleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'language': instance.language,
  'title': instance.title,
  'readingTimeMinutes': instance.readingTimeMinutes,
  'field': instance.field.toJson(),
};

_GlossaryTermModel _$GlossaryTermModelFromJson(Map<String, dynamic> json) =>
    _GlossaryTermModel(
      slug: json['slug'] as String,
      term: json['term'] as String,
      definitionEn: json['definitionEn'] as String? ?? '',
      explanationAr: json['explanationAr'] as String? ?? '',
      articles:
          (json['articles'] as List<dynamic>?)
              ?.map(
                (e) => GlossaryArticleModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <GlossaryArticleModel>[],
    );

Map<String, dynamic> _$GlossaryTermModelToJson(_GlossaryTermModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'term': instance.term,
      'definitionEn': instance.definitionEn,
      'explanationAr': instance.explanationAr,
      'articles': instance.articles.map((e) => e.toJson()).toList(),
    };
