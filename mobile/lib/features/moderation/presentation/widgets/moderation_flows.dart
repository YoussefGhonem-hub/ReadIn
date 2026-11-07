import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../categories/domain/entities/writer_category.dart';
import '../../domain/entities/moderation.dart';
import '../cubit/moderation_action_cubit.dart';
import 'moderation_dialogs.dart';
import 'moderation_labels.dart';

/// A moderator's actions as the reader, a profile and a case page run them (F22): ask (note, length, or confirm for
/// destructive ones), run with the [ModerationActionCubit] above [context], then say it's done or why it failed. Each
/// returns true once the action went through.
abstract final class ModerationFlows {
  /// Hide an article or a comment, with an optional note (the author of an article sees it).
  static Future<bool> hide(BuildContext context, ModerationTargetRef target) async => await hideWithNote(context, target) != null;

  /// [hide], returning the note given ('' for none) once hidden; null when cancelled or refused.
  static Future<String?> hideWithNote(BuildContext context, ModerationTargetRef target) async {
    final l10n = context.l10n;
    final article = target.type == ModerationTargetType.article;
    final note = await showModerationNoteDialog(
      context,
      title: article ? l10n.moderationHideArticleTitle : l10n.moderationHideCommentTitle,
      body: article ? l10n.moderationHideArticleBody : l10n.moderationHideCommentBody,
      confirmLabel: article ? l10n.articleMenuHide : l10n.moderationHideComment,
      noteRequired: false,
      destructive: true,
    );
    if (note == null || !context.mounted) return null;
    final hidden = await _run(
      context,
      ModerationCommand(ModerationActionType.hide, target, note: note),
      article ? l10n.moderationArticleHidden : l10n.commentsHidden,
    );
    return hidden ? note : null;
  }

  static Future<bool> unhide(BuildContext context, ModerationTargetRef target) {
    final l10n = context.l10n;
    return _run(
      context,
      ModerationCommand(ModerationActionType.unhide, target),
      target.type == ModerationTargetType.article ? l10n.moderationArticleUnhidden : l10n.commentsUnhidden,
    );
  }

  static Future<bool> deleteComment(BuildContext context, String commentId) async {
    final l10n = context.l10n;
    final confirmed = await confirmModeration(
      context,
      title: l10n.commentsModDeleteTitle,
      body: l10n.commentsModDeleteBody,
      confirmLabel: l10n.moderationDeleteComment,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
    return _run(context, ModerationCommand(ModerationActionType.delete, ModerationTargetRef.comment(commentId)), l10n.commentsDeleted);
  }

  /// Warn [userId] with a note they have to acknowledge. [resolveReportsOf]: also close the reports of the content the
  /// warning is about.
  static Future<bool> warn(BuildContext context, {required String userId, required String name, ModerationTargetRef? resolveReportsOf}) async {
    final l10n = context.l10n;
    final note = await showModerationNoteDialog(
      context,
      title: l10n.moderationWarnTitle(embedContent(name)),
      body: l10n.moderationWarnBody,
      confirmLabel: l10n.moderationWarnConfirm,
      noteRequired: true,
    );
    if (note == null || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.warn, ModerationTargetRef.user(userId), note: note, resolveReportsOf: resolveReportsOf),
      l10n.moderationWarned,
    );
  }

  /// Suspend [userId] for 1, 3, 7 or 30 days, a custom 1–365 days or permanently, with a reason, and optionally hide
  /// all of their articles and comments too (`users.suspend`; the console's form, F23).
  static Future<bool> suspend(BuildContext context, {required String userId, required String name, ModerationTargetRef? resolveReportsOf}) async {
    final choice = await showSuspendDialog(context, name: embedContent(name));
    if (choice == null || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(
        ModerationActionType.suspend,
        ModerationTargetRef.user(userId),
        note: choice.note,
        durationDays: choice.days,
        resolveReportsOf: resolveReportsOf,
        hideContent: choice.hideContent,
      ),
      context.l10n.moderationSuspended,
    );
  }

  /// Hide all of [userId]'s articles and comments at once (F23, for spam accounts): asks first; "Restore their
  /// content" undoes it. The user gets no notice.
  static Future<bool> hideAllContent(BuildContext context, {required String userId, required String name}) async {
    final l10n = context.l10n;
    final confirmed = await confirmModeration(
      context,
      title: l10n.adminHideContentTitle(embedContent(name)),
      body: l10n.adminHideContentBody,
      confirmLabel: l10n.adminConfirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.hideContent, ModerationTargetRef.user(userId)),
      l10n.adminContentHidden,
    );
  }

  /// Bring back what [hideAllContent] (or a suspension that hid everything) hid and is still hidden (F23).
  static Future<bool> restoreContent(BuildContext context, {required String userId, required String name}) async {
    final l10n = context.l10n;
    final confirmed = await confirmModeration(
      context,
      title: l10n.adminRestoreContentTitle(embedContent(name)),
      body: l10n.adminRestoreContentBody,
      confirmLabel: l10n.adminConfirm,
    );
    if (!confirmed || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.unhideContent, ModerationTargetRef.user(userId)),
      l10n.adminContentRestored,
    );
  }

  static Future<bool> unsuspend(BuildContext context, {required String userId, required String name}) async {
    final l10n = context.l10n;
    final confirmed = await confirmModeration(
      context,
      title: l10n.moderationUnsuspendTitle(embedContent(name)),
      body: l10n.moderationUnsuspendBody,
      confirmLabel: l10n.moderationUnsuspend,
    );
    if (!confirmed || !context.mounted) return false;
    return _run(context, ModerationCommand(ModerationActionType.unsuspend, ModerationTargetRef.user(userId)), l10n.moderationUnsuspended);
  }

  /// Clear the offensive name of one of [userId]'s writer categories (F31): it becomes a neutral placeholder ("قسم 1")
  /// with a new slug, so its old links stop working; its articles stay in it. Asks first, with an optional note for the
  /// log (the writer isn't notified).
  static Future<bool> clearCategory(BuildContext context, {required String userId, required WriterCategory category}) async {
    final l10n = context.l10n;
    final note = await showModerationNoteDialog(
      context,
      title: l10n.moderationClearCategoryTitle(embedContent(category.name)),
      body: l10n.moderationClearCategoryBody,
      confirmLabel: l10n.moderationClearCategory,
      noteRequired: false,
      destructive: true,
    );
    if (note == null || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.clearCategory, ModerationTargetRef.user(userId), note: note, categoryId: category.id),
      l10n.moderationCategoryCleared,
    );
  }

  /// Remove all of [userId]'s social links (F14): asks first, with an optional note for the log; the user isn't
  /// notified.
  static Future<bool> clearLinks(BuildContext context, {required String userId, required String name}) async {
    final l10n = context.l10n;
    final note = await showModerationNoteDialog(
      context,
      title: l10n.moderationClearLinksTitle(embedContent(name)),
      body: l10n.moderationClearLinksBody,
      confirmLabel: l10n.moderationClearLinks,
      noteRequired: false,
      destructive: true,
    );
    if (note == null || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.clearLinks, ModerationTargetRef.user(userId), note: note),
      l10n.moderationLinksCleared,
    );
  }

  /// Remove [userId]'s title (F14): asks first, with an optional note for the log; the user isn't notified.
  static Future<bool> clearHeadline(BuildContext context, {required String userId, required String name}) async {
    final l10n = context.l10n;
    final note = await showModerationNoteDialog(
      context,
      title: l10n.moderationClearHeadlineTitle(embedContent(name)),
      body: l10n.moderationClearHeadlineBody,
      confirmLabel: l10n.moderationClearHeadline,
      noteRequired: false,
      destructive: true,
    );
    if (note == null || !context.mounted) return false;
    return _run(
      context,
      ModerationCommand(ModerationActionType.clearHeadline, ModerationTargetRef.user(userId), note: note),
      l10n.moderationHeadlineCleared,
    );
  }

  /// Close the target's open reports without touching it.
  static Future<bool> dismiss(BuildContext context, ModerationTargetRef target) async {
    final l10n = context.l10n;
    final confirmed = await confirmModeration(
      context,
      title: l10n.moderationDismissTitle,
      body: l10n.moderationDismissBody,
      confirmLabel: l10n.moderationDismiss,
    );
    if (!confirmed || !context.mounted) return false;
    return _run(context, ModerationCommand(ModerationActionType.dismiss, target), l10n.moderationDismissed);
  }

  static Future<bool> _run(BuildContext context, ModerationCommand command, String done) async {
    final failure = await context.read<ModerationActionCubit>().run(command);
    if (!context.mounted) return failure == null;
    if (failure == null) {
      showActionMessage(context, done);
    } else {
      showActionFailure(context, failure);
    }
    return failure == null;
  }
}
