import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/entities/blocks.dart';
import 'block_actions.dart';

/// «هذا الحساب غير متاح» / «هذا المحتوى غير متاح» (F36) for someone the viewer blocked, with «إلغاء الحظر»: on their
/// profile ([account]) and on their article. [onUnblocked] reloads the screen once the API agrees.
class BlockedNotice extends StatelessWidget {
  const BlockedNotice({super.key, required this.person, this.account = false, this.onUnblocked});

  /// The `blockedUser` of a `403 block.blocked`, or the writer blocked from this screen.
  final BlockedPerson person;
  final bool account;
  final VoidCallback? onUnblocked;

  /// The person a `403 block.blocked` names; null for any other failure.
  static BlockedPerson? personOf(Failure? failure) => failure is BlockedFailure
      ? BlockedPerson(id: failure.blockedUserId, username: failure.blockedUsername, displayName: failure.blockedDisplayName)
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ReadInSpace.s6),
        child: Column(
          key: const ValueKey('blocked-notice'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: colors.surfaceVariant, shape: BoxShape.circle),
              child: Icon(Icons.block_rounded, size: 34, color: colors.textSecondary),
            ),
            const SizedBox(height: ReadInSpace.s4),
            Semantics(
              header: true,
              child: Text(
                account ? l10n.blockAccountUnavailable : l10n.blockContentUnavailable,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
              ),
            ),
            if (person.username.isNotEmpty) ...[
              const SizedBox(height: ReadInSpace.s2),
              Text(
                l10n.blockYouBlocked(BlockActions.handle(person.username)),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: ReadInSpace.s4),
            OutlinedButton.icon(
              key: const ValueKey('blocked-notice-unblock'),
              onPressed: () => unawaited(() async {
                if (await BlockActions.unblockPerson(context, person)) onUnblocked?.call();
              }()),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(l10n.blockUnblock),
            ),
          ],
        ),
      ),
    );
  }
}
