import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../domain/entities/blocks.dart';
import '../cubit/blocks_cubit.dart';

/// Block and unblock (F36) from the profile's, a comment's and an article's "⋯", and the "isn't available" states:
/// the confirmation «هل تريد حظر @username؟» (the person is never told), then a toast with Undo, which unblocks and
/// follows them again when the block ended the viewer's follow. Guests get the sign-in prompt.
abstract final class BlockActions {
  /// How long the toast with Undo stays; with a screen reader on it stays until it is closed.
  static const undoDuration = Duration(seconds: 6);

  /// Asks first; true once blocked.
  static Future<bool> block(BuildContext context, {required String userId, required String username}) async {
    if (!requireAccount(context)) return false;
    final blocks = context.read<BlocksCubit>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final keepUndo = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    final confirmed = await confirmBlock(context, username: username);
    if (!confirmed) return false;
    final result = await blocks.block(userId);
    switch (result) {
      case Ok(:final value):
        _show(
          messenger,
          SnackBar(
            content: Text(l10n.blockDone(handle(username))),
            duration: undoDuration,
            persist: keepUndo,
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => unawaited(() async {
                final failure = (await blocks.unblock(userId, restoreFollow: value.followRemoved)).failureOrNull;
                _fail(messenger, l10n, failure);
              }()),
            ),
          ),
        );
        return true;
      case Err(:final failure):
        _fail(messenger, l10n, failure);
        return false;
    }
  }

  /// «إلغاء الحظر»: visible to each other again; follows don't come back.
  static Future<bool> unblock(BuildContext context, {required String userId, required String username}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = (await context.read<BlocksCubit>().unblock(userId)).failureOrNull;
    if (failure == null) {
      _show(messenger, SnackBar(content: Text(l10n.blockUnblocked(handle(username)))));
    } else {
      _fail(messenger, l10n, failure);
    }
    return failure == null;
  }

  /// [BlockedPerson]'s Unblock on an "isn't available" screen.
  static Future<bool> unblockPerson(BuildContext context, BlockedPerson person) =>
      unblock(context, userId: person.id, username: person.username);

  /// The confirmation dialog: «حظر» in the error color, «إلغاء».
  static Future<bool> confirmBlock(BuildContext context, {required String username}) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('block-confirm'),
        title: Text(l10n.blockConfirmTitle(handle(username))),
        content: Text(l10n.blockConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            key: const ValueKey('block-confirm-ok'),
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.colors.error,
              foregroundColor: dialogContext.colors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.blockAction),
          ),
        ],
      ),
    );
    return (confirmed ?? false) && context.mounted;
  }

  /// `@username`, left to right inside an Arabic sentence (SPEC §14).
  static String handle(String username) => Bidi.ltrIsolate('@$username');

  static void _fail(ScaffoldMessengerState? messenger, AppLocalizations l10n, Failure? failure) {
    if (failure == null || failure.code == FailureCodes.requestCancelled) return;
    _show(messenger, SnackBar(content: Text(localizeActionFailure(l10n, failure))));
  }

  static void _show(ScaffoldMessengerState? messenger, SnackBar bar) {
    if (messenger == null || !messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }
}
