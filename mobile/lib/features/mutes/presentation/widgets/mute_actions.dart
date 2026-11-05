import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/mutes.dart';
import '../cubit/mutes_cubit.dart';

/// "قلّل من النوع ده", "كتم الكاتب" and "إلغاء الكتم" with their confirmations (F28). The change shows at once (the
/// cards fold away, [MutesCubit]); the confirmation's Undo puts it back, and a refusal says why and undoes it. The
/// callers ask guests to sign in first.
abstract final class MuteActions {
  /// How long the confirmation with Undo stays; with a screen reader on it stays until it is closed.
  static const undoDuration = Duration(seconds: 6);

  /// "قلّل من النوع ده": the article leaves the lists, and its topic is lowered in For you.
  static Future<void> showLess(BuildContext context, ArticleCard article) async {
    final mutes = context.read<MutesCubit>();
    final feedback = _Feedback.of(context);
    final request = mutes.showLess(article.id);
    feedback.confirm(
      feedback.l10n.showLessDone,
      onUndo: () async {
        // The Undo waits for the mark it undoes; a refused mark has nothing to undo.
        if (await request != null) return;
        feedback.fail(await mutes.undoShowLess(article.id));
      },
    );
    feedback.fail(await request);
  }

  /// "كتم الكاتب": the writer's cards leave the lists and the viewer stops following them. Undo unmutes, and follows
  /// them again when the mute ended a follow.
  static Future<void> muteAuthor(BuildContext context, Author author) =>
      muteUser(context, userId: author.id, name: author.displayName);

  /// "كتم الكاتب" (the article menu), "كتم المستخدم" (a profile's "⋯") and "كتم صاحب التعليق" (a comment's "⋯"): the
  /// same mute, with the same confirmation and Undo.
  static Future<void> muteUser(BuildContext context, {required String userId, required String name}) async {
    final mutes = context.read<MutesCubit>();
    final feedback = _Feedback.of(context);
    final request = mutes.muteUser(userId);
    feedback.confirm(
      feedback.l10n.muteDone(_isolate(name)),
      onUndo: () async {
        if ((await request).valueOrNull case final UserMuteState muted) {
          feedback.fail((await mutes.unmuteUser(userId, restoreFollow: muted.followRemoved)).failureOrNull);
        }
      },
    );
    feedback.fail((await request).failureOrNull);
  }

  /// The profile's and the comment's Mute item: unmutes a writer the viewer muted ([fallback] is what the screen
  /// loaded: `ProfileDto.isMuted`, `CommentDto.isAuthorMuted`), else mutes them.
  static Future<void> toggleUser(
    BuildContext context, {
    required String userId,
    required String name,
    required bool fallback,
  }) =>
      context.read<MutesCubit>().state.isUserMuted(userId, fallback: fallback)
          ? unmuteAuthor(context, userId: userId, name: name)
          : muteUser(context, userId: userId, name: name);

  /// "إلغاء الكتم" (the banner, the menu on a muted writer's article, Settings → Muted): the follow ended by the mute
  /// stays ended.
  static Future<void> unmuteAuthor(BuildContext context, {required String userId, required String name}) async {
    final feedback = _Feedback.of(context);
    final result = await context.read<MutesCubit>().unmuteUser(userId);
    switch (result) {
      case Ok():
        feedback.say(feedback.l10n.muteUnmuted(_isolate(name)));
      case Err(:final failure):
        feedback.fail(failure);
    }
  }

  /// A name in its own direction inside the sentence (SPEC §14).
  static String _isolate(String text) => '${Bidi.fsi}$text${Bidi.pdi}';
}

/// The snack bars of [MuteActions], kept from the context that started the action: the card that asked may fold away
/// before the answer comes.
class _Feedback {
  _Feedback(this.l10n, this.messenger, {required this.keepUndo});

  factory _Feedback.of(BuildContext context) => _Feedback(
        context.l10n,
        ScaffoldMessenger.maybeOf(context),
        keepUndo: MediaQuery.maybeAccessibleNavigationOf(context) ?? false,
      );

  final AppLocalizations l10n;
  final ScaffoldMessengerState? messenger;
  final bool keepUndo;

  void say(String message) => _show(SnackBar(content: Text(message)));

  void confirm(String message, {required Future<void> Function() onUndo}) => _show(SnackBar(
        content: Text(message),
        duration: MuteActions.undoDuration,
        persist: keepUndo,
        action: SnackBarAction(label: l10n.undo, onPressed: () => unawaited(onUndo())),
      ));

  /// A refusal, in place of the confirmation; nothing for null or a repeated tap.
  void fail(Failure? failure) {
    if (failure == null || failure.code == FailureCodes.requestCancelled) return;
    say(localizeActionFailure(l10n, failure));
  }

  void _show(SnackBar bar) {
    final messenger = this.messenger;
    if (messenger == null || !messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }
}
