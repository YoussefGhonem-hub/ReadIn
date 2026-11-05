import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../article/data/models/article_models.dart';
import '../../../follow/data/models/follow_models.dart';
import '../models/explore_models.dart';

part 'explore_api.g.dart';

/// Explore and the field pages (F15), guests allowed (a Bearer fills the viewer's reaction, save and follows). Field
/// and topic follows go through the interests endpoints (`InterestsApi`).
@lazySingleton
@RestApi()
abstract class ExploreApi {
  @factoryMethod
  factory ExploreApi(Dio dio) = _ExploreApi;

  /// Every section of Explore.
  @GET('/explore')
  Future<ExploreModel> getExplore();

  /// "Trending this week" (`trending`) or "Most saved" (`most-saved`) in full.
  @GET('/explore/{ranking}')
  Future<ArticleCardPageModel> getRanking(
    @Path('ranking') String ranking,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// The field page's header. `404 field.not_found`.
  @GET('/fields/{slug}')
  Future<FieldPageModel> getField(@Path('slug') String slug);

  /// The field's articles, newest first; [topic] narrows them to one topic. `404 field.not_found`, `404 topic.not_found`.
  @GET('/fields/{slug}/articles')
  Future<ArticleCardPageModel> getFieldArticles(
    @Path('slug') String slug,
    @Query('topic') String? topic,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// "Top writers in this field". `404 field.not_found`.
  @GET('/fields/{slug}/writers')
  Future<List<UserSummaryModel>> getFieldWriters(@Path('slug') String slug, @Query('limit') int limit);
}
