import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../follow/data/models/follow_models.dart';
import '../models/search_models.dart';

part 'search_api.g.dart';

/// Search (F16), guests allowed (a Bearer fills the viewer's own state on cards and writers). `GET /search` answers one
/// tab per call, so each `type` has its own method. Rate limit `search`: 60 a minute.
@lazySingleton
@RestApi()
abstract class SearchApi {
  @factoryMethod
  factory SearchApi(Dio dio) = _SearchApi;

  /// `type=articles`, with the Articles tab's filters (null = not sent).
  @GET('/search')
  Future<SearchArticlePageModel> searchArticles(
    @Query('q') String query,
    @Query('type') String type,
    @Query('field') String? field,
    @Query('lang') String? language,
    @Query('minMinutes') int? minMinutes,
    @Query('maxMinutes') int? maxMinutes,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// `type=users`.
  @GET('/search')
  Future<UserSummaryPageModel> searchUsers(
    @Query('q') String query,
    @Query('type') String type,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// `type=topics`.
  @GET('/search')
  Future<SearchTopicPageModel> searchTopics(
    @Query('q') String query,
    @Query('type') String type,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  /// `type=tags`.
  @GET('/search')
  Future<TagPageModel> searchTags(
    @Query('q') String query,
    @Query('type') String type,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );
}
