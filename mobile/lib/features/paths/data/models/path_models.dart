import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/learning_path.dart';

part 'path_models.freezed.dart';
part 'path_models.g.dart';

/// `PathArticleRefDto`.
@freezed
abstract class PathArticleRefModel with _$PathArticleRefModel {
  const PathArticleRefModel._();

  const factory PathArticleRefModel({
    required String id,
    required String slug,
    required String title,
    required String language,
    required int position,
    @Default(1) int readingTimeMinutes,
  }) = _PathArticleRefModel;

  factory PathArticleRefModel.fromJson(Map<String, dynamic> json) => _$PathArticleRefModelFromJson(json);

  PathArticleRef toEntity() => PathArticleRef(
        id: id,
        slug: slug,
        title: title,
        language: language,
        position: position,
        readingTimeMinutes: readingTimeMinutes,
      );
}

/// `PathProgressDto`.
@freezed
abstract class PathProgressModel with _$PathProgressModel {
  const PathProgressModel._();

  const factory PathProgressModel({
    @Default(0) int readCount,
    @Default(0) int total,
    @Default(0) int percent,
    PathArticleRefModel? next,
  }) = _PathProgressModel;

  factory PathProgressModel.fromJson(Map<String, dynamic> json) => _$PathProgressModelFromJson(json);

  PathProgress toEntity() => PathProgress(readCount: readCount, total: total, percent: percent, next: next?.toEntity());
}

/// `PathEnrollmentDto`.
@freezed
abstract class PathEnrollmentModel with _$PathEnrollmentModel {
  const PathEnrollmentModel._();

  const factory PathEnrollmentModel({required DateTime enrolledAt, DateTime? completedAt}) = _PathEnrollmentModel;

  factory PathEnrollmentModel.fromJson(Map<String, dynamic> json) => _$PathEnrollmentModelFromJson(json);

  PathEnrollment toEntity() => PathEnrollment(enrolledAt: enrolledAt, completedAt: completedAt);
}

/// `PathCardDto`.
@freezed
abstract class PathCardModel with _$PathCardModel {
  const PathCardModel._();

  const factory PathCardModel({
    required String id,
    required String slug,
    required String title,
    String? description,
    required FieldRefModel field,
    @Default(0) int articleCount,
    @Default(0) int readingTimeMinutes,
    String? coverUrl,
    PathProgressModel? progress,
    PathEnrollmentModel? enrollment,
  }) = _PathCardModel;

  factory PathCardModel.fromJson(Map<String, dynamic> json) => _$PathCardModelFromJson(json);

  LearningPath toEntity() => LearningPath(
        id: id,
        slug: slug,
        title: title,
        description: description == null || description!.trim().isEmpty ? null : description,
        field: field.toEntity(),
        articleCount: articleCount,
        readingTimeMinutes: readingTimeMinutes,
        coverUrl: coverUrl == null || coverUrl!.isEmpty ? null : coverUrl,
        progress: progress?.toEntity(),
        enrollment: enrollment?.toEntity(),
      );
}

/// `PathItemDto`.
@freezed
abstract class PathItemModel with _$PathItemModel {
  const PathItemModel._();

  const factory PathItemModel({required int position, required ArticleCardModel article, @Default(false) bool isRead}) =
      _PathItemModel;

  factory PathItemModel.fromJson(Map<String, dynamic> json) => _$PathItemModelFromJson(json);

  PathItem toEntity() => PathItem(position: position, article: article.toEntity(), isRead: isRead);
}

/// `PathDetailsDto`: the card fields (`PathDetailsDto extends PathCardDto`) plus `items`.
@freezed
abstract class PathDetailsModel with _$PathDetailsModel {
  const PathDetailsModel._();

  const factory PathDetailsModel({
    required String id,
    required String slug,
    required String title,
    String? description,
    required FieldRefModel field,
    @Default(0) int articleCount,
    @Default(0) int readingTimeMinutes,
    String? coverUrl,
    PathProgressModel? progress,
    PathEnrollmentModel? enrollment,
    @Default(<PathItemModel>[]) List<PathItemModel> items,
  }) = _PathDetailsModel;

  factory PathDetailsModel.fromJson(Map<String, dynamic> json) => _$PathDetailsModelFromJson(json);

  PathCardModel toCard() => PathCardModel(
        id: id,
        slug: slug,
        title: title,
        description: description,
        field: field,
        articleCount: articleCount,
        readingTimeMinutes: readingTimeMinutes,
        coverUrl: coverUrl,
        progress: progress,
        enrollment: enrollment,
      );

  PathDetails toEntity() => PathDetails(
        path: toCard().toEntity(),
        items: [for (final item in items) item.toEntity()]..sort((a, b) => a.position.compareTo(b.position)),
      );
}

/// `ArticlePathDto`.
@freezed
abstract class ArticlePathModel with _$ArticlePathModel {
  const ArticlePathModel._();

  const factory ArticlePathModel({
    required PathCardModel path,
    required int position,
    required int total,
    PathArticleRefModel? previous,
    ArticleCardModel? next,
  }) = _ArticlePathModel;

  factory ArticlePathModel.fromJson(Map<String, dynamic> json) => _$ArticlePathModelFromJson(json);

  ArticlePath toEntity() => ArticlePath(
        path: path.toEntity(),
        position: position,
        total: total,
        previous: previous?.toEntity(),
        next: next?.toEntity(),
      );
}
