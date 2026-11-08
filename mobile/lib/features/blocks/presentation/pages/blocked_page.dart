import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/blocks.dart';
import '../cubit/blocked_list_cubit.dart';
import '../cubit/blocks_cubit.dart';
import '../widgets/block_actions.dart';

/// Settings → Blocked accounts (F18, F36): everyone the viewer blocked, newest first, each with «إلغاء الحظر».
class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key, this.cubit});

  /// The web's path. It needs an account: the router sends guests away.
  static const path = '/settings/blocked';

  /// Test seam; the app takes the cubit from DI.
  final BlockedListCubit? cubit;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => (cubit ?? getIt<BlockedListCubit>())..load(), child: const BlockedView());
}

/// The page once its [BlockedListCubit] is provided (and the app's [BlocksCubit]).
class BlockedView extends StatelessWidget {
  const BlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BlockedListCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedTitle)),
      body: BlocBuilder<BlockedListCubit, BlockedListState>(
        builder: (context, state) => switch (state.status) {
          BlockedListStatus.loading => const Center(child: CircularProgressIndicator()),
          BlockedListStatus.failure => PageBlock(
              margin: const EdgeInsets.only(top: PageBlock.gap),
              child: ErrorView(failure: state.failure!, onRetry: cubit.load),
            ),
          BlockedListStatus.ready when state.items.isEmpty => PageBlock(
              margin: const EdgeInsets.only(top: PageBlock.gap),
              child: EmptyView(icon: Icons.block_rounded, title: l10n.blockedEmptyTitle, body: l10n.blockedEmptyBody),
            ),
          BlockedListStatus.ready => RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
                children: [
                  PageBlock(
                    margin: const EdgeInsets.only(top: PageBlock.gap),
                    padding: PageBlock.gutters,
                    child: Column(
                      children: [
                        for (var i = 0; i < state.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _BlockedRow(key: ValueKey('blocked-${state.items[i].user.id}'), blocked: state.items[i]),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(PageBlock.gutter),
                    child: Text(
                      l10n.blockedFollowsNote,
                      style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({super.key, required this.blocked});

  final BlockedUser blocked;

  Future<void> _unblock(BuildContext context) async {
    final user = blocked.user;
    final failure = await context.read<BlockedListCubit>().unblock(user.id);
    if (!context.mounted) return;
    if (failure != null) return showActionFailure(context, failure);
    showActionMessage(context, context.l10n.blockUnblocked(BlockActions.handle(user.username)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final user = blocked.user;
    final pending = context.select((BlocksCubit c) => c.state.isPending(user.id));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
      child: Row(
        children: [
          UserAvatar(name: user.displayName, url: user.avatarUrl, size: 44),
          const SizedBox(width: ReadInSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: BidiText(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge),
                    ),
                    if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                  ],
                ),
                Text(Bidi.ltrIsolate('@${user.username}'), maxLines: 1, style: context.textTheme.bodySmall),
                Text(
                  l10n.blockedSince(formatDate(blocked.blockedAt.toLocal(), l10n.localeName)),
                  style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: ReadInSpace.s2),
          Semantics(
            button: true,
            label: l10n.blockMenuUnblockUser(BlockActions.handle(user.username)),
            excludeSemantics: true,
            child: OutlinedButton(
              onPressed: pending ? null : () => unawaited(_unblock(context)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
              ),
              child: Text(l10n.blockUnblock),
            ),
          ),
        ],
      ),
    );
  }
}
