import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/saved.dart';

part 'saved_models.freezed.dart';
part 'saved_models.g.dart';

/// `SaveStateDto`.
@freezed
abstract class SaveStateModel with _$SaveStateModel {
  const SaveStateModel._();

  const factory SaveStateModel({required bool isSaved, @Default(0) int saveCount}) = _SaveStateModel;

  factory SaveStateModel.fromJson(Map<String, dynamic> json) => _$SaveStateModelFromJson(json);

  SaveState toEntity() => SaveState(isSaved: isSaved, saveCount: saveCount);
}

/// `SavedArticleDto`.
@freezed
abstract class SavedArticleModel with _$SavedArticleModel {
  const SavedArticleModel._();

  const factory SavedArticleModel({
    required DateTime savedAt,
    @Default(<String>[]) List<String> collectionIds,
    required ArticleCardModel article,
  }) = _SavedArticleModel;

  factory SavedArticleModel.fromJson(Map<String, dynamic> json) => _$SavedArticleModelFromJson(json);

  /// Every item of this list is saved, whatever the card says.
  SavedArticle toEntity() => SavedArticle(
        savedAt: savedAt,
        collectionIds: collectionIds,
        article: article.copyWith(isSaved: true).toEntity(),
      );
}

/// `CursorPage<SavedArticleDto>`.
@freezed
abstract class SavedArticlePageModel with _$SavedArticlePageModel {
  const factory SavedArticlePageModel({
    @Default(<SavedArticleModel>[]) List<SavedArticleModel> items,
    String? nextCursor,
  }) = _SavedArticlePageModel;

  factory SavedArticlePageModel.fromJson(Map<String, dynamic> json) => _$SavedArticlePageModelFromJson(json);
}

/// `CollectionDto`.
@freezed
abstract class CollectionModel with _$CollectionModel {
  const CollectionModel._();

  const factory CollectionModel({
    required String id,
    required String name,
    @Default(0) int articleCount,
    required DateTime createdAt,
  }) = _CollectionModel;

  factory CollectionModel.fromJson(Map<String, dynamic> json) => _$CollectionModelFromJson(json);

  ArticleCollection toEntity() => ArticleCollection(id: id, name: name, articleCount: articleCount, createdAt: createdAt);
}

/// `{ name }` for creating or renaming a collection.
@freezed
abstract class CollectionNameRequest with _$CollectionNameRequest {
  const factory CollectionNameRequest({required String name}) = _CollectionNameRequest;

  factory CollectionNameRequest.fromJson(Map<String, dynamic> json) => _$CollectionNameRequestFromJson(json);
}
