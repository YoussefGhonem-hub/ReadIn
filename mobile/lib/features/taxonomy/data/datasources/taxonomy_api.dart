import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/taxonomy_models.dart';

part 'taxonomy_api.g.dart';

@lazySingleton
@RestApi()
abstract class TaxonomyApi {
  @factoryMethod
  factory TaxonomyApi(Dio dio) = _TaxonomyApi;

  @GET('/fields')
  Future<List<FieldModel>> getFields();

  @GET('/fields/{slug}/topics')
  Future<List<TopicModel>> getTopics(@Path('slug') String slug);
}
