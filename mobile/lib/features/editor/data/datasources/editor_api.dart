import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../media/data/models/media_models.dart';
import '../models/editor_models.dart';

part 'editor_api.g.dart';

/// Writing endpoints (Bearer, permission `articles.create`).
@lazySingleton
@RestApi()
abstract class EditorApi {
  @factoryMethod
  factory EditorApi(Dio dio) = _EditorApi;

  @POST('/articles')
  Future<CreatedArticleModel> createArticle(@Body() CreateArticleRequestModel body);

  @PUT('/articles/{id}/attachments')
  Future<void> setAttachments(@Path('id') String id, @Body() SetAttachmentsRequestModel body);

  @POST('/articles/{id}/publish')
  Future<void> publish(@Path('id') String id);
}
