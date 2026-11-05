import '../../../../core/errors/result.dart';
import '../entities/mutes.dart';

/// Mute & feedback (F28). Every route needs a session; writes use the `writes` rate limit.
abstract interface class MutesRepository {
  /// `PUT /users/{id}/mute` (idempotent): ends the viewer's follow of them. `400 mute.self`, `mute.system_account`,
  /// `mute.limit`; `404 user.not_found`.
  Future<Result<UserMuteState>> muteUser(String userId);

  /// `DELETE /users/{id}/mute?restoreFollow=`: [restoreFollow] follows the writer again (a mute's Undo).
  Future<Result<UserMuteState>> unmuteUser(String userId, {bool restoreFollow = false});

  /// `PUT|DELETE /me/mutes/fields/{id}`: `404 field.not_found` when muting an unknown field.
  Future<Result<ContentMutes>> setFieldMuted(String fieldId, {required bool muted});

  /// `PUT|DELETE /me/mutes/topics/{id}`: `404 topic.not_found` when muting an unknown topic.
  Future<Result<ContentMutes>> setTopicMuted(String topicId, {required bool muted});

  /// `GET /me/mutes`: Settings → Muted.
  Future<Result<Mutes>> getMutes();

  /// `PUT|DELETE /articles/{id}/show-less` ("قلّل من النوع ده" and its Undo): `400 mute.own_article`,
  /// `404 article.not_found`.
  Future<Result<void>> setShowLess(String articleId, {required bool showLess});
}
