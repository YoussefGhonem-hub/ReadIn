import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/continue_reading.dart';

part 'continue_reading_models.freezed.dart';
part 'continue_reading_models.g.dart';

/// `ContinueReadingDto` (F03).
@freezed
abstract class ContinueReadingModel with _$ContinueReadingModel {
  const ContinueReadingModel._();

  const factory ContinueReadingModel({
    required ArticleCardModel article,
    @Default(0) int percent,
    required String language,
    required DateTime updatedAt,
  }) = _ContinueReadingModel;

  factory ContinueReadingModel.fromJson(Map<String, dynamic> json) => _$ContinueReadingModelFromJson(json);

  ContinueReading toEntity() =>
      ContinueReading(article: article.toEntity(), percent: percent, language: language, updatedAt: updatedAt);
}
