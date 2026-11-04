import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/path_models.dart';

part 'paths_api.g.dart';

/// Learning paths (F09). The reads take an optional Bearer (signed in: `progress` and `enrollment` are filled);
/// `/me/paths` and enrolling need a session.
@lazySingleton
@RestApi()
abstract class PathsApi {
  @factoryMethod
  factory PathsApi(Dio dio) = _PathsApi;

  /// Published paths in editorial order; `field` = field slug.
  @GET('/paths')
  Future<List<PathCardModel>> getPaths(@Query('field') String? field);

  /// `404 path.not_found`.
  @GET('/paths/{slug}')
  Future<PathDetailsModel> getPath(@Path('slug') String slug);

  /// 200 with an `ArticlePathDto`, or 204 when the article is in no published path: the raw response is decoded by
  /// the repository.
  @GET('/articles/{id}/path')
  Future<HttpResponse<dynamic>> getArticlePath(@Path('id') String articleId);

  /// That user's enrolled paths. `403 profile.stats_private` unless their reading stats are visible.
  @GET('/users/{username}/paths')
  Future<List<PathCardModel>> getUserPaths(@Path('username') String username);

  /// The viewer's enrolled paths: in progress first, then completed.
  @GET('/me/paths')
  Future<List<PathCardModel>> getMyPaths();

  /// 200 with a `PathCardDto`, or 204 when no enrolled path is in progress.
  @GET('/me/paths/active')
  Future<HttpResponse<dynamic>> getActivePath();

  /// Enroll (idempotent). `404 path.not_found`.
  @PUT('/me/paths/{pathId}')
  Future<PathCardModel> enroll(@Path('pathId') String pathId);

  /// Leave (idempotent); the reading history stays.
  @DELETE('/me/paths/{pathId}')
  Future<void> leave(@Path('pathId') String pathId);
}
