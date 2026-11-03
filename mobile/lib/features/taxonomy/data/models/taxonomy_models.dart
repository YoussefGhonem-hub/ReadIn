import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/field.dart';

part 'taxonomy_models.freezed.dart';
part 'taxonomy_models.g.dart';

/// `FieldDto` (docs/api/contract-v1.md).
@freezed
abstract class FieldModel with _$FieldModel {
  const FieldModel._();

  const factory FieldModel({
    required String id,
    required String slug,
    required String nameAr,
    required String nameEn,
    String? name,
    @Default('book-open') String icon,
    @Default('primary') String color,
    @Default(false) bool isSensitive,
    @Default(0) int topicCount,
  }) = _FieldModel;

  factory FieldModel.fromJson(Map<String, dynamic> json) => _$FieldModelFromJson(json);

  Field toEntity() => Field(
        id: id,
        slug: slug,
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        isSensitive: isSensitive,
        topicCount: topicCount,
      );
}

/// `TopicDto` (docs/api/contract-v1.md).
@freezed
abstract class TopicModel with _$TopicModel {
  const TopicModel._();

  const factory TopicModel({
    required String id,
    required String fieldId,
    required String slug,
    required String nameAr,
    required String nameEn,
    String? name,
  }) = _TopicModel;

  factory TopicModel.fromJson(Map<String, dynamic> json) => _$TopicModelFromJson(json);

  Topic toEntity() => Topic(id: id, fieldId: fieldId, slug: slug, nameAr: nameAr, nameEn: nameEn);
}
