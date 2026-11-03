import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/field.dart';
import '../repositories/taxonomy_repository.dart';

@injectable
class GetFields {
  const GetFields(this._repository);

  final TaxonomyRepository _repository;

  Future<Result<List<Field>>> call({bool refresh = false}) => _repository.getFields(refresh: refresh);
}

@injectable
class GetTopics {
  const GetTopics(this._repository);

  final TaxonomyRepository _repository;

  Future<Result<List<Topic>>> call(String fieldSlug) => _repository.getTopics(fieldSlug);
}
