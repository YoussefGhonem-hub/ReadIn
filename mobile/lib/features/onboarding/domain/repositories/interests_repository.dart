import '../../../../core/errors/result.dart';

/// What an interest is: a whole field, or one topic of a field.
enum InterestKind {
  field('fields'),
  topic('topics');

  const InterestKind(this.path);

  /// The segment of `/me/interests/{fields|topics}/{id}`.
  final String path;
}

abstract interface class InterestsRepository {
  /// `PUT /me/interests` — at least 3 field + topic ids combined.
  Future<Result<void>> saveInterests({required List<String> fieldIds, required List<String> topicIds});

  /// `PUT` ([followed]) or `DELETE /me/interests/{fields|topics}/{id}`: one interest at a time, after onboarding.
  /// Unfollowing fails with `user.interests.min_three` when fewer than 3 would remain.
  Future<Result<void>> setInterest(InterestKind kind, String id, {required bool followed});
}
