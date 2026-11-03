import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/follow.dart';

abstract interface class FollowRepository {
  /// `PUT /users/{id}/follow` (idempotent): `400 follow.self`, `404 user.not_found`.
  Future<Result<FollowState>> follow(String userId);

  /// `DELETE /users/{id}/follow` (idempotent).
  Future<Result<FollowState>> unfollow(String userId);

  /// `GET /users/{id}/followers?q=`, newest first. [query] matches the display name or @username.
  Future<Result<CursorPage<UserSummary>>> getFollowers(String userId, {String? query, String? cursor, int limit = 20});

  /// `GET /users/{id}/following?q=`, newest first.
  Future<Result<CursorPage<UserSummary>>> getFollowing(String userId, {String? query, String? cursor, int limit = 20});

  /// `GET /users/suggested`: writers whose fields overlap the viewer's interests, verified first.
  Future<Result<List<UserSummary>>> getSuggested({int limit = 10});

  /// `PUT|DELETE /me/interests/fields/{id}`: following a field is an interest. Removing one that would leave fewer
  /// than 3 fails with `user.interests.min_three`.
  Future<Result<Interests>> setFieldFollowed(String fieldId, {required bool followed});

  /// `PUT|DELETE /me/interests/topics/{id}`.
  Future<Result<Interests>> setTopicFollowed(String topicId, {required bool followed});
}
