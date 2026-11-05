import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../article/data/models/article_models.dart';
import '../models/tag_models.dart';

part 'tags_api.g.dart';

/// The tag page (F32), guests allowed (a Bearer fills the viewer's reaction, save and follow on the cards). The editor's
/// suggestions, `GET /tags?q=`, live in `ArticleEditorApi`.
@lazySingleton
@RestApi()
abstract class TagsApi {
  @factoryMethod
  factory TagsApi(Dio dio) = _TagsApi;

  /// The page's header. `404 tag.not_found` for an unknown or hidden tag.
  @GET('/tags/{slug}')
  Future<TagModel> getTag(@Path('slug') String slug);

  /// Every published article with the tag, from all writers, newest first. Same `404`.
  @GET('/tags/{slug}/articles')
  Future<ArticleCardPageModel> getArticles(
    @Path('slug') String slug,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );
}
