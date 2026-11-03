import '../../../../core/errors/result.dart';

abstract interface class InterestsRepository {
  /// `PUT /me/interests` — at least 3 field + topic ids combined.
  Future<Result<void>> saveInterests({required List<String> fieldIds, required List<String> topicIds});
}
