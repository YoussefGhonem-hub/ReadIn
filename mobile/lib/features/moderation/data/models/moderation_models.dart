import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../categories/data/models/category_models.dart';
import '../../../follow/data/models/follow_models.dart';
import '../../domain/entities/moderation.dart';

part 'moderation_models.freezed.dart';
part 'moderation_models.g.dart';

/// `POST /reports` body.
@freezed
abstract class ReportRequest with _$ReportRequest {
  const factory ReportRequest({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) = _ReportRequest;

  factory ReportRequest.fromJson(Map<String, dynamic> json) => _$ReportRequestFromJson(json);
}

/// `{ targetType, targetId }` (`ModerationActionRequest.resolveReportsOf`).
@freezed
abstract class ModerationTargetRefModel with _$ModerationTargetRefModel {
  const factory ModerationTargetRefModel({required String targetType, required String targetId}) = _ModerationTargetRefModel;

  factory ModerationTargetRefModel.fromJson(Map<String, dynamic> json) => _$ModerationTargetRefModelFromJson(json);
}

/// `POST /moderation/actions` body. Null fields are left out (`durationDays` omitted = a permanent suspension).
@freezed
abstract class ModerationActionRequest with _$ModerationActionRequest {
  const factory ModerationActionRequest({
    required String action,
    required String targetType,
    required String targetId,
    String? note,
    int? durationDays,
    ModerationTargetRefModel? resolveReportsOf,
    String? categoryId,
  }) = _ModerationActionRequest;

  factory ModerationActionRequest.fromJson(Map<String, dynamic> json) => _$ModerationActionRequestFromJson(json);

  factory ModerationActionRequest.of(ModerationCommand command) => ModerationActionRequest(
        action: command.action.wire,
        targetType: command.target.type.name,
        targetId: command.target.id,
        note: command.note,
        durationDays: command.durationDays,
        resolveReportsOf: switch (command.resolveReportsOf) {
          final ref? => ModerationTargetRefModel(targetType: ref.type.name, targetId: ref.id),
          null => null,
        },
        categoryId: command.categoryId,
      );
}

/// `GET /moderation/summary`: `{ open: { article, comment, user, total } }`.
@freezed
abstract class ModerationSummaryModel with _$ModerationSummaryModel {
  const ModerationSummaryModel._();

  const factory ModerationSummaryModel({@Default(ModerationOpenCountsModel()) ModerationOpenCountsModel open}) =
      _ModerationSummaryModel;

  factory ModerationSummaryModel.fromJson(Map<String, dynamic> json) => _$ModerationSummaryModelFromJson(json);

  ModerationSummary toEntity() =>
      ModerationSummary(article: open.article, comment: open.comment, user: open.user, total: open.total);
}

@freezed
abstract class ModerationOpenCountsModel with _$ModerationOpenCountsModel {
  const factory ModerationOpenCountsModel({
    @Default(0) int article,
    @Default(0) int comment,
    @Default(0) int user,
    @Default(0) int total,
  }) = _ModerationOpenCountsModel;

  factory ModerationOpenCountsModel.fromJson(Map<String, dynamic> json) => _$ModerationOpenCountsModelFromJson(json);
}

/// `ModerationTargetDto`.
@freezed
abstract class ModerationTargetModel with _$ModerationTargetModel {
  const ModerationTargetModel._();

  const factory ModerationTargetModel({
    required String state,
    AuthorModel? author,
    String? title,
    String? slug,
    String? language,
    String? body,
    String? articleId,
    String? articleSlug,
    String? articleTitle,
    DateTime? suspendedUntil,
    @Default(0) int warningCount,
  }) = _ModerationTargetModel;

  factory ModerationTargetModel.fromJson(Map<String, dynamic> json) => _$ModerationTargetModelFromJson(json);

  ModerationTarget toEntity() => ModerationTarget(
        // An unknown state shows as an ordinary target.
        state: enumFromWire(ModerationTargetState.values, state) ?? ModerationTargetState.visible,
        author: author?.toEntity(),
        title: title,
        slug: slug,
        language: language,
        body: body,
        articleId: articleId,
        articleSlug: articleSlug,
        articleTitle: articleTitle,
        suspendedUntil: suspendedUntil,
        warningCount: warningCount,
      );
}

/// `ModerationQueueItemDto`.
@freezed
abstract class ModerationQueueItemModel with _$ModerationQueueItemModel {
  const ModerationQueueItemModel._();

  const factory ModerationQueueItemModel({
    required String targetType,
    required String targetId,
    required String status,
    @Default(0) int reportCount,
    @Default(<String, int>{}) Map<String, int> reasons,
    required DateTime firstReportedAt,
    required DateTime lastReportedAt,
    DateTime? closedAt,
    required ModerationTargetModel target,
  }) = _ModerationQueueItemModel;

  factory ModerationQueueItemModel.fromJson(Map<String, dynamic> json) => _$ModerationQueueItemModelFromJson(json);

  /// Null for a target type or status this app version doesn't know.
  ModerationQueueItem? toEntity() {
    final type = enumFromWire(ModerationTargetType.values, targetType);
    final status = enumFromWire(ReportStatus.values, this.status);
    if (type == null || status == null) return null;
    final counts = <ReportReason, int>{
      for (final MapEntry(:key, :value) in reasons.entries)
        if (enumFromWire(ReportReason.values, key) case final reason? when value > 0) reason: value,
    };
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ModerationQueueItem(
      targetType: type,
      targetId: targetId,
      status: status,
      reportCount: reportCount,
      reasons: {for (final entry in sorted) entry.key: entry.value},
      firstReportedAt: firstReportedAt,
      lastReportedAt: lastReportedAt,
      closedAt: closedAt,
      target: target.toEntity(),
    );
  }
}

/// `CursorPage<ModerationQueueItemDto>`.
@freezed
abstract class ModerationQueuePageModel with _$ModerationQueuePageModel {
  const factory ModerationQueuePageModel({
    @Default(<ModerationQueueItemModel>[]) List<ModerationQueueItemModel> items,
    String? nextCursor,
  }) = _ModerationQueuePageModel;

  factory ModerationQueuePageModel.fromJson(Map<String, dynamic> json) => _$ModerationQueuePageModelFromJson(json);
}

/// `ModerationReportDto`.
@freezed
abstract class ModerationReportModel with _$ModerationReportModel {
  const ModerationReportModel._();

  const factory ModerationReportModel({
    required String id,
    UserSummaryModel? reporter,
    required String reason,
    String? details,
    required String status,
    required DateTime createdAt,
    DateTime? closedAt,
    UserSummaryModel? closedBy,
  }) = _ModerationReportModel;

  factory ModerationReportModel.fromJson(Map<String, dynamic> json) => _$ModerationReportModelFromJson(json);

  ModerationReport toEntity() => ModerationReport(
        id: id,
        reporter: reporter?.toEntity(),
        reason: enumFromWire(ReportReason.values, reason) ?? ReportReason.other,
        details: details,
        status: enumFromWire(ReportStatus.values, status) ?? ReportStatus.open,
        createdAt: createdAt,
        closedAt: closedAt,
        closedBy: closedBy?.toEntity(),
      );
}

/// `ModerationActionDto`.
@freezed
abstract class ModerationActionModel with _$ModerationActionModel {
  const ModerationActionModel._();

  const factory ModerationActionModel({
    required String id,
    required String action,
    required String targetType,
    required String targetId,
    String? targetLabel,
    UserSummaryModel? targetUser,
    UserSummaryModel? moderator,
    String? note,
    DateTime? suspendedUntil,
    @Default(0) int reportsClosed,
    required DateTime createdAt,
  }) = _ModerationActionModel;

  factory ModerationActionModel.fromJson(Map<String, dynamic> json) => _$ModerationActionModelFromJson(json);

  /// Null for a target type this app version doesn't know.
  ModerationLogEntry? toEntity() {
    final type = enumFromWire(ModerationTargetType.values, targetType);
    if (type == null) return null;
    return ModerationLogEntry(
      id: id,
      action: ModerationLogAction.fromWire(action),
      targetType: type,
      targetId: targetId,
      targetLabel: targetLabel,
      targetUser: targetUser?.toEntity(),
      moderator: moderator?.toEntity(),
      note: note,
      suspendedUntil: suspendedUntil,
      reportsClosed: reportsClosed,
      createdAt: createdAt,
    );
  }
}

/// `CursorPage<ModerationActionDto>`.
@freezed
abstract class ModerationActionPageModel with _$ModerationActionPageModel {
  const factory ModerationActionPageModel({
    @Default(<ModerationActionModel>[]) List<ModerationActionModel> items,
    String? nextCursor,
  }) = _ModerationActionPageModel;

  factory ModerationActionPageModel.fromJson(Map<String, dynamic> json) => _$ModerationActionPageModelFromJson(json);
}

/// `ModerationCaseDto`.
@freezed
abstract class ModerationCaseModel with _$ModerationCaseModel {
  const factory ModerationCaseModel({
    required ModerationQueueItemModel item,
    @Default(<ModerationReportModel>[]) List<ModerationReportModel> reports,
    @Default(<ModerationActionModel>[]) List<ModerationActionModel> history,
    // F31: a user case's writer categories, empty ones included ([] for content cases; null from an older API).
    List<WriterCategoryModel>? categories,
  }) = _ModerationCaseModel;

  factory ModerationCaseModel.fromJson(Map<String, dynamic> json) => _$ModerationCaseModelFromJson(json);
}

/// `ModerationNoticeDto.article`.
@freezed
abstract class ModerationNoticeArticleModel with _$ModerationNoticeArticleModel {
  const factory ModerationNoticeArticleModel({required String id, required String slug, required String title}) =
      _ModerationNoticeArticleModel;

  factory ModerationNoticeArticleModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticeArticleModelFromJson(json);
}

/// `ModerationNoticeDto`.
@freezed
abstract class ModerationNoticeModel with _$ModerationNoticeModel {
  const ModerationNoticeModel._();

  const factory ModerationNoticeModel({
    required String id,
    required String kind,
    String? note,
    ModerationNoticeArticleModel? article,
    required DateTime createdAt,
  }) = _ModerationNoticeModel;

  factory ModerationNoticeModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticeModelFromJson(json);

  /// Null for a kind this app version doesn't know.
  ModerationNotice? toEntity() {
    final kind = ModerationNoticeKind.fromWire(this.kind);
    if (kind == null) return null;
    final a = article;
    return ModerationNotice(
      id: id,
      kind: kind,
      note: note,
      article: a == null ? null : ModerationNoticeArticle(id: a.id, slug: a.slug, title: a.title),
      createdAt: createdAt,
    );
  }
}

/// `GET /me/moderation-notices`: `{ items }`.
@freezed
abstract class ModerationNoticesModel with _$ModerationNoticesModel {
  const factory ModerationNoticesModel({@Default(<ModerationNoticeModel>[]) List<ModerationNoticeModel> items}) =
      _ModerationNoticesModel;

  factory ModerationNoticesModel.fromJson(Map<String, dynamic> json) => _$ModerationNoticesModelFromJson(json);
}
