import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';
import '../../../categories/domain/entities/writer_category.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../profile/domain/entities/profile_link.dart';

/// Why something is reported (F22).
enum ReportReason { spam, misinformation, harassment, copyright, other }

/// What can be reported and moderated. The wire name is [name].
enum ModerationTargetType { article, comment, user }

/// A report's state; the queue is filtered on it. The wire name is [name].
enum ReportStatus { open, resolved, dismissed }

/// A target's state: article / comment `visible | hidden | deleted`, user `active | suspended | deleted`.
enum ModerationTargetState { visible, hidden, deleted, active, suspended }

/// `ModerationActionRequest.action`. Allowed pairs: comment hide/unhide/delete/dismiss, article hide/unhide/dismiss,
/// user warn/suspend/unsuspend/clear_category/clear_links/clear_headline/dismiss (suspend and unsuspend also need
/// `users.suspend`).
enum ModerationActionType {
  hide,
  unhide,
  delete,
  warn,
  suspend,
  unsuspend,

  /// Renames one of the user's writer categories to a neutral placeholder (F31), with [ModerationCommand.categoryId].
  clearCategory,

  /// Removes all of the user's social links (F14).
  clearLinks,

  /// Removes the user's title (F14).
  clearHeadline,
  dismiss;

  /// The wire name: `clear_category`, `clear_links`, `clear_headline`, otherwise [name].
  String get wire => switch (this) {
        clearCategory => 'clear_category',
        clearLinks => 'clear_links',
        clearHeadline => 'clear_headline',
        _ => name,
      };
}

/// `ModerationActionDto.action`: a row of the moderation log.
enum ModerationLogAction {
  commentHide('comment.hide'),
  commentUnhide('comment.unhide'),
  commentDelete('comment.delete'),
  articleHide('article.hide'),
  articleUnhide('article.unhide'),
  userWarn('user.warn'),
  userSuspend('user.suspend'),
  userUnsuspend('user.unsuspend'),
  userClearCategory('user.clear_category'),
  userClearLinks('user.clear_links'),
  userClearHeadline('user.clear_headline'),
  reportsDismiss('reports.dismiss'),

  /// An action this app version doesn't know yet.
  unknown('');

  const ModerationLogAction(this.wire);

  final String wire;

  static ModerationLogAction fromWire(String value) =>
      values.firstWhere((action) => action.wire == value && action != unknown, orElse: () => unknown);
}

/// `ModerationNoticeDto.kind`.
enum ModerationNoticeKind {
  warning('warning'),
  articleHidden('article_hidden');

  const ModerationNoticeKind(this.wire);

  final String wire;

  static ModerationNoticeKind? fromWire(String value) => values.where((kind) => kind.wire == value).firstOrNull;
}

/// Reads a wire name of [values]; null for a name this app version doesn't know.
T? enumFromWire<T extends Enum>(List<T> values, String? name) => name == null ? null : values.asNameMap()[name];

/// What a report or a moderation action points at.
class ModerationTargetRef extends Equatable {
  const ModerationTargetRef(this.type, this.id);

  const ModerationTargetRef.article(this.id) : type = ModerationTargetType.article;
  const ModerationTargetRef.comment(this.id) : type = ModerationTargetType.comment;
  const ModerationTargetRef.user(this.id) : type = ModerationTargetType.user;

  final ModerationTargetType type;
  final String id;

  @override
  List<Object?> get props => [type, id];
}

/// `GET /moderation/summary`: targets with open reports (the badge).
class ModerationSummary extends Equatable {
  const ModerationSummary({this.article = 0, this.comment = 0, this.user = 0, this.total = 0});

  final int article;
  final int comment;
  final int user;
  final int total;

  @override
  List<Object?> get props => [article, comment, user, total];
}

/// `ModerationTargetDto`: what the moderator looks at. [author] is the content's author, or the user itself for a user
/// target; null for a deleted account.
class ModerationTarget extends Equatable {
  const ModerationTarget({
    required this.state,
    this.author,
    this.title,
    this.slug,
    this.language,
    this.body,
    this.articleId,
    this.articleSlug,
    this.articleTitle,
    this.suspendedUntil,
    this.warningCount = 0,
    this.links,
  });

  final ModerationTargetState state;

  /// The user's title is [Author.headline] (F14).
  final Author? author;

  // Article
  final String? title;
  final String? slug;
  final String? language;

  // Comment
  final String? body;
  final String? articleId;
  final String? articleSlug;
  final String? articleTitle;

  // User: when the suspension ends (null = permanent, while [state] is suspended), and the warnings so far.
  final DateTime? suspendedUntil;
  final int warningCount;

  /// User targets: their social links (F14), in their order; null for content targets (or an older API).
  final List<ProfileLink>? links;

  bool get isHidden => state == ModerationTargetState.hidden;
  bool get isDeleted => state == ModerationTargetState.deleted;
  bool get isSuspended => state == ModerationTargetState.suspended;

  @override
  List<Object?> get props =>
      [state, author, title, slug, language, body, articleId, articleSlug, articleTitle, suspendedUntil, warningCount, links];
}

/// `ModerationQueueItemDto`: one target and its reports in one [status].
class ModerationQueueItem extends Equatable {
  const ModerationQueueItem({
    required this.targetType,
    required this.targetId,
    required this.status,
    required this.reportCount,
    required this.firstReportedAt,
    required this.lastReportedAt,
    required this.target,
    this.reasons = const {},
    this.closedAt,
  });

  final ModerationTargetType targetType;
  final String targetId;
  final ReportStatus status;
  final int reportCount;

  /// Reports per reason, most first.
  final Map<ReportReason, int> reasons;
  final DateTime firstReportedAt;
  final DateTime lastReportedAt;

  /// Resolved / dismissed lists: when the reports were closed.
  final DateTime? closedAt;
  final ModerationTarget target;

  ModerationTargetRef get ref => ModerationTargetRef(targetType, targetId);

  @override
  List<Object?> get props =>
      [targetType, targetId, status, reportCount, reasons, firstReportedAt, lastReportedAt, closedAt, target];
}

/// `ModerationReportDto`. [reporter] and [closedBy] are null for deleted accounts.
class ModerationReport extends Equatable {
  const ModerationReport({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporter,
    this.details,
    this.closedAt,
    this.closedBy,
  });

  final String id;
  final UserSummary? reporter;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final UserSummary? closedBy;

  @override
  List<Object?> get props => [id, reporter, reason, details, status, createdAt, closedAt, closedBy];
}

/// `ModerationActionDto`: a row of the moderation log.
class ModerationLogEntry extends Equatable {
  const ModerationLogEntry({
    required this.id,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.targetLabel,
    this.targetUser,
    this.moderator,
    this.note,
    this.suspendedUntil,
    this.reportsClosed = 0,
  });

  final String id;
  final ModerationLogAction action;
  final ModerationTargetType targetType;
  final String targetId;

  /// The article title, the start of the comment or `@username`, as it was then.
  final String? targetLabel;

  /// The affected user (the author, or the user target).
  final UserSummary? targetUser;

  /// Null when the moderator's account was deleted.
  final UserSummary? moderator;
  final String? note;

  /// `user.suspend`: when it ends (null = permanent).
  final DateTime? suspendedUntil;
  final int reportsClosed;
  final DateTime createdAt;

  ModerationTargetRef get ref => ModerationTargetRef(targetType, targetId);

  @override
  List<Object?> get props =>
      [id, action, targetType, targetId, targetLabel, targetUser, moderator, note, suspendedUntil, reportsClosed, createdAt];
}

/// `ModerationCaseDto`: a target, all its reports (newest first) and its history (newest first; for content, the
/// actions on its author too). A user's case also has their writer categories (F31), so an offensive name can be
/// cleared.
class ModerationCase extends Equatable {
  const ModerationCase({required this.item, this.reports = const [], this.history = const [], this.categories});

  final ModerationQueueItem item;
  final List<ModerationReport> reports;
  final List<ModerationLogEntry> history;

  /// A user case: the user's categories, empty ones included, in their order. Empty for article and comment cases;
  /// null from an API that doesn't send them.
  final List<WriterCategory>? categories;

  int get openReports => reports.where((r) => r.status == ReportStatus.open).length;

  @override
  List<Object?> get props => [item, reports, history, categories];
}

/// The article of an `article_hidden` notice.
class ModerationNoticeArticle extends Equatable {
  const ModerationNoticeArticle({required this.id, required this.slug, required this.title});

  final String id;
  final String slug;
  final String title;

  @override
  List<Object?> get props => [id, slug, title];
}

/// `ModerationNoticeDto`: a warning, or one of your articles was hidden. Shown once, until acknowledged.
class ModerationNotice extends Equatable {
  const ModerationNotice({required this.id, required this.kind, required this.createdAt, this.note, this.article});

  final String id;
  final ModerationNoticeKind kind;
  final String? note;
  final ModerationNoticeArticle? article;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, kind, note, article, createdAt];
}

/// A moderator's action (`POST /moderation/actions`).
class ModerationCommand extends Equatable {
  const ModerationCommand(this.action, this.target, {this.note, this.durationDays, this.resolveReportsOf, this.categoryId});

  final ModerationActionType action;
  final ModerationTargetRef target;

  /// ≤ 500; required for warn and suspend.
  final String? note;

  /// Suspend only: 1–365 days; null = permanent.
  final int? durationDays;

  /// Also closes these open reports, e.g. warning an author from an article's case.
  final ModerationTargetRef? resolveReportsOf;

  /// `clear_category` only: which of the user's categories (F31).
  final String? categoryId;

  @override
  List<Object?> get props => [action, target, note, durationDays, resolveReportsOf, categoryId];
}
