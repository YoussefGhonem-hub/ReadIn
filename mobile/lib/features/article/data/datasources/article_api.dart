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
}
