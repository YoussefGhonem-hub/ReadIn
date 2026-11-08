import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/moderation.dart';

/// Reports, the moderation queue, actions, the log and the notices of the affected user (F22).
abstract interface class ModerationRepository {
  /// `POST /reports` (`reports.create`). Reporting the same target again is a no-op. [alsoBlock] blocks the target's
  /// author too (F36; `400 block.limit` saves neither).
  Future<Result<void>> report(ModerationTargetRef target, ReportReason reason, {String? details, bool alsoBlock = false});

  /// `GET /moderation/summary`: targets with open reports.
  Future<Result<ModerationSummary>> summary();

  /// `GET /moderation/reports`: targets with reports in [status], grouped by target.
  Future<Result<CursorPage<ModerationQueueItem>>> queue(
    ReportStatus status, {
    ModerationTargetType? type,
    String? cursor,
    int limit = 20,
  });

  /// `GET /moderation/reports/{targetType}/{targetId}`.
  Future<Result<ModerationCase>> getCase(ModerationTargetRef target);

  /// `POST /moderation/actions`.
  Future<Result<void>> act(ModerationCommand command);

  /// `GET /moderation/actions`: the log, newest first.
  Future<Result<CursorPage<ModerationLogEntry>>> log({
    ModerationTargetType? targetType,
    String? targetUserId,
    String? moderatorId,
    String? cursor,
    int limit = 20,
  });

  /// `GET /me/moderation-notices`: unacknowledged, oldest first.
  Future<Result<List<ModerationNotice>>> notices();

  /// `POST /me/moderation-notices/{id}/acknowledge` (idempotent).
  Future<Result<void>> acknowledge(String noticeId);
}
