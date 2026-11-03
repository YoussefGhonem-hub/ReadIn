import '../../../../core/errors/result.dart';
import '../entities/field.dart';

abstract interface class TaxonomyRepository {
  /// Enabled fields, ordered (`GET /fields`). Cached for the session.
  Future<Result<List<Field>>> getFields({bool refresh = false});

  /// Topics of a field (`GET /fields/{slug}/topics`).
  Future<Result<List<Topic>>> getTopics(String fieldSlug);
}
