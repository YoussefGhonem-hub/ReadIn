import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/highlight_models.dart';

part 'highlights_api.g.dart';

/// Highlights (F30). Reading an article's is open to guests; writes need `highlights.create` (guests never call them:
/// the sign-in prompt comes first).
@lazySingleton
@RestApi()
abstract class HighlightsApi {
  @factoryMethod
  factory HighlightsApi(Dio dio) = _HighlightsApi;

  /// `lang` = the version on screen; the answer's `language` says which version the highlights belong to.
  @GET('/articles/{id}/highlights')
  Future<ArticleHighlightsModel> forArticle(@Path('id') String articleId, @Query('lang') String language);

  /// `201` made (maybe joining some of yours), `200` already inside one of yours.
  @POST('/articles/{id}/highlights')
  Future<HighlightCreatedModel> create(@Path('id') String articleId, @Body() CreateHighlightRequest body);

  @DELETE('/highlights/{id}')
  Future<void> remove(@Path('id') String highlightId);

  /// The profile's Saved → Highlights: one group per article version, newest first.
  @GET('/me/highlights')
  Future<HighlightGroupPageModel> mine(@Query('cursor') String? cursor, @Query('limit') int limit);
}
