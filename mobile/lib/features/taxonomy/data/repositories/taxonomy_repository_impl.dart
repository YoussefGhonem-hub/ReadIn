import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/field.dart';
import '../../domain/repositories/taxonomy_repository.dart';
import '../datasources/taxonomy_api.dart';

@LazySingleton(as: TaxonomyRepository)
class TaxonomyRepositoryImpl implements TaxonomyRepository {
  TaxonomyRepositoryImpl(this._api);

  final TaxonomyApi _api;
  List<Field>? _fields;
  final _topics = <String, List<Topic>>{};

  @override
  Future<Result<List<Field>>> getFields({bool refresh = false}) async {
    if (!refresh && _fields != null) return Ok(_fields!);
    final result = await guardApi(() async => (await _api.getFields()).map((m) => m.toEntity()).toList());
    if (result case Ok(:final value)) _fields = value;
    return result;
  }

  @override
  Future<Result<List<Topic>>> getTopics(String fieldSlug) async {
    final cached = _topics[fieldSlug];
    if (cached != null) return Ok(cached);
    final result = await guardApi(() async => (await _api.getTopics(fieldSlug)).map((m) => m.toEntity()).toList());
    if (result case Ok(:final value)) _topics[fieldSlug] = value;
    return result;
  }
}
