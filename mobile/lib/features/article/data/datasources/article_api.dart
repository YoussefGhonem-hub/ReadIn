import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/article_models.dart';

part 'article_api.g.dart';

@lazySingleton
@RestApi()
abstract class ArticleApi {
  @factoryMethod
  factory ArticleApi(Dio dio) = _ArticleApi;

  @GET('/articles/{slug}')
  Future<ArticleDetailsModel> getArticle(@Path('slug') String slug, @Query('lang') String? lang);

  /// Cards for the end of the reader (F04). `lang` is the version being read.
  @GET('/articles/{id}/related')
  Future<List<ArticleCardModel>> getRelated(@Path('id') String id, @Query('lang') String? lang, @Query('limit') int limit);

  /// The beginning of the article as RDoc, for "Read more" on a post card (F34). Anonymous allowed.
  @GET('/articles/{id}/preview')
  Future<ArticlePreviewModel> getPreview(@Path('id') String id, @Query('lang') String? lang);
}
