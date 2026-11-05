import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_api.dart';
import '../models/moderation_models.dart';

@LazySingleton(as: ModerationRepository)
class ModerationRepositoryImpl implements ModerationRepository {
  ModerationRepositoryImpl(this._api);

  final ModerationApi _api;

  @override
  Future<Result<void>> report(ModerationTargetRef target, ReportReason reason, {String? details}) => guardApi(
        () => _api.report(ReportRequest(targetType: target.type.name, targetId: target.id, reason: reason.name, details: details)),
      );

  @override
  Future<Result<ModerationSummary>> summary() => guardApi(() async => (await _api.summary()).toEntity());

  @override
  Future<Result<CursorPage<ModerationQueueItem>>> queue(
    ReportStatus status, {
    ModerationTargetType? type,
    String? cursor,
    int limit = 20,
  }) =>
      guardApi(() async {
        final page = await _api.queue(status.name, type?.name, cursor, limit);
        return CursorPage(items: [for (final item in page.items) ?item.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<ModerationCase>> getCase(ModerationTargetRef target) => guardApi(() async {
        final dto = await _api.getCase(target.type.name, target.id);
        final item = dto.item.toEntity();
        if (item == null) throw const FormatException('Unknown moderation target');
        return ModerationCase(
          item: item,
          reports: [for (final report in dto.reports) report.toEntity()],
          history: [for (final action in dto.history) ?action.toEntity()],
          categories: switch (dto.categories) {
            final categories? => [for (final c in categories) c.toEntity()],
            null => null,
          },
        );
      });

  @override
  Future<Result<void>> act(ModerationCommand command) => guardApi(() => _api.act(ModerationActionRequest.of(command)));

  @override
  Future<Result<CursorPage<ModerationLogEntry>>> log({
    ModerationTargetType? targetType,
    String? targetUserId,
    String? moderatorId,
    String? cursor,
    int limit = 20,
  }) =>
      guardApi(() async {
        final page = await _api.log(targetUserId, moderatorId, targetType?.name, cursor, limit);
        return CursorPage(items: [for (final action in page.items) ?action.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<List<ModerationNotice>>> notices() =>
      guardApi(() async => [for (final notice in (await _api.notices()).items) ?notice.toEntity()]);

  @override
  Future<Result<void>> acknowledge(String noticeId) => guardApi(() => _api.acknowledge(noticeId));
}
