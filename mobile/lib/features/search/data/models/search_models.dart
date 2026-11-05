import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../tags/data/models/tag_models.dart';
import '../../domain/entities/search.dart';

part 'search_models.freezed.dart';
part 'search_models.g.dart';

/// `SearchArticleDto`.
@freezed
abstract class SearchArticleModel with _$SearchArticleModel {
  const SearchArticleModel._();

  const factory SearchArticleModel({required ArticleCardModel article, String? matchedIn}) = _SearchArticleModel;

  factory SearchArticleModel.fromJson(Map<String, dynamic> json) => _$SearchArticleModelFromJson(json);

  SearchArticle toEntity() => SearchArticle(article: article.toEntity(), matchedIn: SearchMatch.fromWire(matchedIn));
}

/// `CursorPage<SearchArticleDto>`.
@freezed
abstract class SearchArticlePageModel with _$SearchArticlePageModel {
  const factory SearchArticlePageModel({
    @Default(<SearchArticleModel>[]) List<SearchArticleModel> items,
    String? nextCursor,
  }) = _SearchArticlePageModel;

  factory SearchArticlePageModel.fromJson(Map<String, dynamic> json) => _$SearchArticlePageModelFromJson(json);
}

/// `SearchTopicDto`.
@freezed
abstract class SearchTopicModel with _$SearchTopicModel {
  const SearchTopicModel._();

  const factory SearchTopicModel({
    String? kind,
    required String id,
    required String name,
    @Default('') String nameAr,
    @Default('') String nameEn,
    required String fieldSlug,
    String? topicSlug,
    @Default('') String fieldName,
    @Default('book-open') String icon,
    @Default('primary') String color,
    @Default(0) int articleCount,
  }) = _SearchTopicModel;

  factory SearchTopicModel.fromJson(Map<String, dynamic> json) => _$SearchTopicModelFromJson(json);

  SearchTopic toEntity() => SearchTopic(
        kind: SearchTopicKind.fromWire(kind),
        id: id,
        name: name,
        nameAr: nameAr,
        nameEn: nameEn,
        fieldSlug: fieldSlug,
        topicSlug: topicSlug,
        fieldName: fieldName.isEmpty ? name : fieldName,
        icon: icon,
        color: color,
        articleCount: articleCount,
      );
}

/// `CursorPage<SearchTopicDto>`.
@freezed
abstract class SearchTopicPageModel with _$SearchTopicPageModel {
  const factory SearchTopicPageModel({
    @Default(<SearchTopicModel>[]) List<SearchTopicModel> items,
    String? nextCursor,
  }) = _SearchTopicPageModel;

  factory SearchTopicPageModel.fromJson(Map<String, dynamic> json) => _$SearchTopicPageModelFromJson(json);
}

/// `CursorPage<TagDto>`.
@freezed
abstract class TagPageModel with _$TagPageModel {
  const factory TagPageModel({@Default(<TagModel>[]) List<TagModel> items, String? nextCursor}) = _TagPageModel;

  factory TagPageModel.fromJson(Map<String, dynamic> json) => _$TagPageModelFromJson(json);
}
