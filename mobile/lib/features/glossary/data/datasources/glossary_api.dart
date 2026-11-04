import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/glossary_models.dart';

part 'glossary_api.g.dart';

/// Glossary (F21). Public: guests read definitions too.
@lazySingleton
@RestApi()
abstract class GlossaryApi {
  @factoryMethod
  factory GlossaryApi(Dio dio) = _GlossaryApi;

  @GET('/glossary/{slug}')
  Future<GlossaryTermModel> getTerm(@Path('slug') String slug, @Query('lang') String lang);

  /// The editor's term picker: the English term or the slug, those starting with [q] first, then A–Z.
  @GET('/glossary')
  Future<List<GlossaryTermSummaryModel>> search(@Query('q') String q, @Query('limit') int limit);
}
