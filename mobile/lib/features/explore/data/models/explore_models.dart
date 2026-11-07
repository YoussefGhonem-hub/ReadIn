import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../follow/data/models/follow_models.dart';
import '../../../paths/data/models/path_models.dart';
import '../../domain/entities/explore.dart';

part 'explore_models.freezed.dart';
part 'explore_models.g.dart';

/// `FieldSummaryDto`: a field tile on Explore.
@freezed
abstract class FieldSummaryModel with _$FieldSummaryModel {
  const FieldSummaryModel._();

  const factory FieldSummaryModel({
    required String id,
    required String slug,
    @Default('') String name,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default('book-open') String icon,
    @Default('primary') String color,
    @Default(0) int articleCount,
  }) = _FieldSummaryModel;

  factory FieldSummaryModel.fromJson(Map<String, dynamic> json) => _$FieldSummaryModelFromJson(json);

  FieldSummary toEntity() => FieldSummary(
        id: id,
        slug: slug,
        name: name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : nameAr),
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        color: color,
        articleCount: articleCount,
      );
}

/// `ExploreDto` (`GET /explore`): an empty section is `[]`.
@freezed
abstract class ExploreModel with _$ExploreModel {
  const ExploreModel._();

  const factory ExploreModel({
    @Default(<FieldSummaryModel>[]) List<FieldSummaryModel> fields,
    @Default(<ArticleCardModel>[]) List<ArticleCardModel> trending,
    @Default(<ArticleCardModel>[]) List<ArticleCardModel> mostSaved,
    @Default(<UserSummaryModel>[]) List<UserSummaryModel> newWriters,
    @Default(<PathCardModel>[]) List<PathCardModel> featuredPaths,
    // F23: the articles the SuperAdmin featured (≤ 6, most recently featured first); [] hides the section.
    @Default(<ArticleCardModel>[]) List<ArticleCardModel> featuredArticles,
  }) = _ExploreModel;

  factory ExploreModel.fromJson(Map<String, dynamic> json) => _$ExploreModelFromJson(json);

  ExploreSections toEntity() => ExploreSections(
        fields: [for (final f in fields) f.toEntity()],
        trending: [for (final a in trending) a.toEntity()],
        mostSaved: [for (final a in mostSaved) a.toEntity()],
        newWriters: [for (final u in newWriters) u.toEntity()],
        featuredPaths: [for (final p in featuredPaths) p.toEntity()],
        featuredArticles: [for (final a in featuredArticles) a.toEntity()],
      );
}

/// `FieldPageTopicDto`: a topic chip.
@freezed
abstract class FieldPageTopicModel with _$FieldPageTopicModel {
  const FieldPageTopicModel._();

  const factory FieldPageTopicModel({
    required String id,
    required String slug,
    @Default('') String name,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default(0) int articleCount,
    @Default(false) bool isFollowing,
  }) = _FieldPageTopicModel;

  factory FieldPageTopicModel.fromJson(Map<String, dynamic> json) => _$FieldPageTopicModelFromJson(json);

  FieldTopic toEntity() => FieldTopic(
        id: id,
        slug: slug,
        name: name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : nameAr),
        nameAr: nameAr,
        nameEn: nameEn,
        articleCount: articleCount,
        isFollowing: isFollowing,
      );
}

/// `FieldPageDto` (`GET /fields/{slug}`): the field page's header and topic chips.
@freezed
abstract class FieldPageModel with _$FieldPageModel {
  const FieldPageModel._();

  const factory FieldPageModel({
    required String id,
    required String slug,
    @Default('') String name,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default('book-open') String icon,
    @Default('primary') String color,
    @Default(false) bool isSensitive,
    @Default(0) int articleCount,
    @Default(0) int followerCount,
    @Default(false) bool isFollowing,
    @Default(<FieldPageTopicModel>[]) List<FieldPageTopicModel> topics,
  }) = _FieldPageModel;

  factory FieldPageModel.fromJson(Map<String, dynamic> json) => _$FieldPageModelFromJson(json);

  FieldDetails toEntity() => FieldDetails(
        id: id,
        slug: slug,
        name: name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : nameAr),
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        color: color,
        isSensitive: isSensitive,
        articleCount: articleCount,
        followerCount: followerCount,
        isFollowing: isFollowing,
        topics: [for (final t in topics) t.toEntity()],
      );
}
