import '../../../../core/errors/result.dart';
import '../entities/glossary_term.dart';

abstract interface class GlossaryRepository {
  /// `GET /glossary/{slug}?lang=` (F21). [language] is the version being read and picks the titles of the term's
  /// articles. `404 glossary.term_not_found`.
  Future<Result<GlossaryTerm>> getTerm(String slug, {required String language});
}
