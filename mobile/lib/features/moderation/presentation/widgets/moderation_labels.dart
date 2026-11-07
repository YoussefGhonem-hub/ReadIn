import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../domain/entities/moderation.dart';

/// ar/en text and icons for the moderation enums (F22).
extension ModerationLabels on AppLocalizations {
  String reportReason(ReportReason reason) => switch (reason) {
        ReportReason.spam => reportReasonSpam,
        ReportReason.misinformation => reportReasonMisinformation,
        ReportReason.harassment => reportReasonHarassment,
        ReportReason.copyright => reportReasonCopyright,
        ReportReason.other => reportReasonOther,
      };

  String reportTitle(ModerationTargetType type) => switch (type) {
        ModerationTargetType.article => reportTitleArticle,
        ModerationTargetType.comment => reportTitleComment,
        ModerationTargetType.user => reportTitleUser,
      };

  String targetType(ModerationTargetType type) => switch (type) {
        ModerationTargetType.article => moderationTypeArticle,
        ModerationTargetType.comment => moderationTypeComment,
        ModerationTargetType.user => moderationTypeUser,
      };

  /// The type filter's chips: null = all.
  String typeFilter(ModerationTargetType? type) => switch (type) {
        null => moderationFilterAll,
        ModerationTargetType.article => moderationFilterArticles,
        ModerationTargetType.comment => moderationFilterComments,
        ModerationTargetType.user => moderationFilterUsers,
      };

  String caseTitle(ModerationTargetType type) => switch (type) {
        ModerationTargetType.article => moderationCaseArticle,
        ModerationTargetType.comment => moderationCaseComment,
        ModerationTargetType.user => moderationCaseUser,
      };

  String reportStatus(ReportStatus status) => switch (status) {
        ReportStatus.open => moderationStatusOpen,
        ReportStatus.resolved => moderationStatusResolved,
        ReportStatus.dismissed => moderationStatusDismissed,
      };

  /// Hidden, deleted and suspended targets get a chip; visible and active ones none.
  String? targetState(ModerationTargetState state) => switch (state) {
        ModerationTargetState.hidden => moderationStateHidden,
        ModerationTargetState.deleted => moderationStateDeleted,
        ModerationTargetState.suspended => moderationStateSuspended,
        ModerationTargetState.visible || ModerationTargetState.active => null,
      };

  String logAction(ModerationLogAction action) => switch (action) {
        ModerationLogAction.commentHide => moderationLogCommentHide,
        ModerationLogAction.commentUnhide => moderationLogCommentUnhide,
        ModerationLogAction.commentDelete => moderationLogCommentDelete,
        ModerationLogAction.articleHide => moderationLogArticleHide,
        ModerationLogAction.articleUnhide => moderationLogArticleUnhide,
        ModerationLogAction.userWarn => moderationLogUserWarn,
        ModerationLogAction.userSuspend => moderationLogUserSuspend,
        ModerationLogAction.userUnsuspend => moderationLogUserUnsuspend,
        ModerationLogAction.userClearCategory => moderationLogUserClearCategory,
        ModerationLogAction.userClearLinks => moderationLogUserClearLinks,
        ModerationLogAction.userClearHeadline => moderationLogUserClearHeadline,
        ModerationLogAction.userHideContent => adminLogUserHideContent,
        ModerationLogAction.userUnhideContent => adminLogUserUnhideContent,
        ModerationLogAction.reportsDismiss => moderationLogReportsDismiss,
        ModerationLogAction.unknown => moderationLogOther,
      };

  /// "1 day", "3 days", "7 days", "30 days" or "Permanently".
  String suspensionLength(int? days) => days == null ? moderationPermanent : moderationDays(days);

  /// "Suspended until {date}" (local time) or "Permanently suspended".
  String suspendedUntil(DateTime? until) =>
      until == null ? moderationSuspendedForever : moderationSuspendedUntil(formatDateTime(until, localeName));
}

/// User content (a title, a name, a note) inside a translated sentence: one first-strong isolate, so all of it keeps its
/// own direction wherever the sentence puts it, with its own opposite-script runs isolated too (SPEC §14.2).
String embedContent(String text) {
  final own = Bidi.detect(text) ?? TextDirection.ltr;
  return '${Bidi.fsi}${Bidi.isolateOppositeRuns(text, own)}${Bidi.pdi}';
}

IconData targetTypeIcon(ModerationTargetType type) => switch (type) {
      ModerationTargetType.article => Icons.article_outlined,
      ModerationTargetType.comment => Icons.chat_bubble_outline_rounded,
      ModerationTargetType.user => Icons.person_outline_rounded,
    };

IconData logActionIcon(ModerationLogAction action) => switch (action) {
      ModerationLogAction.commentHide || ModerationLogAction.articleHide => Icons.visibility_off_outlined,
      ModerationLogAction.commentUnhide || ModerationLogAction.articleUnhide => Icons.visibility_outlined,
      ModerationLogAction.commentDelete => Icons.delete_outline_rounded,
      ModerationLogAction.userWarn => Icons.report_gmailerrorred_rounded,
      ModerationLogAction.userSuspend => Icons.block_rounded,
      ModerationLogAction.userUnsuspend => Icons.lock_open_rounded,
      ModerationLogAction.userClearCategory => Icons.folder_off_outlined,
      ModerationLogAction.userClearLinks => Icons.link_off_rounded,
      ModerationLogAction.userClearHeadline => Icons.badge_outlined,
      ModerationLogAction.userHideContent => Icons.hide_source_rounded,
      ModerationLogAction.userUnhideContent => Icons.restore_rounded,
      ModerationLogAction.reportsDismiss => Icons.done_all_rounded,
      ModerationLogAction.unknown => Icons.shield_outlined,
    };
