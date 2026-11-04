import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/glossary_term.dart';
import '../repositories/glossary_repository.dart';

/// The definition sheet of a glossary term tapped in the reader (F21).
@injectable
class GetGlossaryTerm {
  const GetGlossaryTerm(this._repository);

  final GlossaryRepository _repository;

  Future<Result<GlossaryTerm>> call(String slug, {required String language}) =>
      _repository.getTerm(slug, language: language);
}
