import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/glossary_term.dart';
import '../../domain/repositories/glossary_repository.dart';
import '../datasources/glossary_api.dart';

@LazySingleton(as: GlossaryRepository)
class GlossaryRepositoryImpl implements GlossaryRepository {
  GlossaryRepositoryImpl(this._api);

  final GlossaryApi _api;

  /// Terms fetched since the app started, per term and article language (which picks the titles of the term's
  /// articles). Glossary terms only change with a deploy, so a term opened twice is fetched once. Failures,
  /// "not in the glossary yet" included, aren't kept.
  final _cache = <(String, String), GlossaryTerm>{};

  @override
  Future<Result<GlossaryTerm>> getTerm(String slug, {required String language}) async {
    final key = (slug, language);
    final cached = _cache[key];
    if (cached != null) return Ok(cached);
    final result = await guardApi(() async => (await _api.getTerm(slug, language)).toEntity());
    if (result case Ok(:final value)) _cache[key] = value;
    return result;
  }
}
