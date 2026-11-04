import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/glossary_term.dart';
import '../repositories/glossary_repository.dart';

/// The editor's term picker (F21): glossary terms matching what the writer typed (the English term or the slug).
@injectable
class SearchGlossaryTerms {
  const SearchGlossaryTerms(this._repository);

  final GlossaryRepository _repository;

  Future<Result<List<GlossaryTermSummary>>> call(String query, {int limit = 8}) => _repository.search(query, limit: limit);
}
