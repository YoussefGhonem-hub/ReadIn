import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/moderation.dart';
import '../repositories/moderation_repository.dart';

String? _trimmed(String? text) {
  final value = text?.trim();
  return value == null || value.isEmpty ? null : value;
}

/// Reports an article, a comment, a user or a repost (F22) with a reason and optional details; [alsoBlock] blocks the
/// target's author in the same step (F36).
@injectable
class SubmitReport {
  const SubmitReport(this._repository);

  final ModerationRepository _repository;

  static const maxDetailsLength = 500;

  Future<Result<void>> call(ModerationTargetRef target, ReportReason reason, {String? details, bool alsoBlock = false}) =>
      _repository.report(target, reason, details: _trimmed(details), alsoBlock: alsoBlock);
}

@injectable
class GetModerationSummary {
  const GetModerationSummary(this._repository);

  final ModerationRepository _repository;

  Future<Result<ModerationSummary>> call() => _repository.summary();
}

/// The queue: targets with reports in a status, optionally of one type.
@injectable
class GetModerationQueue {
  const GetModerationQueue(this._repository);

  final ModerationRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ModerationQueueItem>>> call(ReportStatus status, {ModerationTargetType? type, String? cursor}) =>
      _repository.queue(status, type: type, cursor: cursor, limit: pageSize);
}

@injectable
class GetModerationCase {
  const GetModerationCase(this._repository);

  final ModerationRepository _repository;

  Future<Result<ModerationCase>> call(ModerationTargetRef target) => _repository.getCase(target);
}

/// Hide, unhide, delete, warn, suspend, unsuspend or dismiss.
@injectable
class TakeModerationAction {
  const TakeModerationAction(this._repository);

  final ModerationRepository _repository;

  static const maxNoteLength = 500;

  /// The suspension lengths offered (days, F23: 1, 3, 7 or 30, a custom number, or permanently); null = permanent.
  static const suspensionDays = <int?>[1, 3, 7, 30, null];

  /// A custom suspension: 1–365 days.
  static const minSuspensionDays = 1;
  static const maxSuspensionDays = 365;

  /// The console's form asks for a reason of 5–500 characters to suspend (SPEC F23); the server only requires one.
  static const minSuspensionReason = 5;

  Future<Result<void>> call(ModerationCommand command) => _repository.act(ModerationCommand(
        command.action,
        command.target,
        note: _trimmed(command.note),
        durationDays: command.durationDays,
        resolveReportsOf: command.resolveReportsOf,
        categoryId: command.categoryId,
        hideContent: command.hideContent,
      ));
}

/// The moderation log, newest first.
@injectable
class GetModerationLog {
  const GetModerationLog(this._repository);

  final ModerationRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<ModerationLogEntry>>> call({ModerationTargetType? targetType, String? cursor}) =>
      _repository.log(targetType: targetType, cursor: cursor, limit: pageSize);
}

/// The signed-in user's unacknowledged warnings and hidden-article notices.
@injectable
class GetModerationNotices {
  const GetModerationNotices(this._repository);

  final ModerationRepository _repository;

  Future<Result<List<ModerationNotice>>> call() => _repository.notices();
}

@injectable
class AcknowledgeModerationNotice {
  const AcknowledgeModerationNotice(this._repository);

  final ModerationRepository _repository;

  Future<Result<void>> call(String noticeId) => _repository.acknowledge(noticeId);
}
