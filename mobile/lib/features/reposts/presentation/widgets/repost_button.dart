import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../reactions/presentation/widgets/reaction_button.dart' show ActionBarItem;
import 'repost_caption_sheet.dart';
import 'repost_menu.dart';

/// Repost (F29) with its count beside it (none at 0), on the post card's action bar and in the reader's. A tap opens a
/// small menu: "Repost" (at once, rolled back with a message when the API refuses) and "Repost with your thoughts" (the
/// caption sheet), or, once reposted, "Edit your thoughts" (the sheet, prefilled) and "Undo repost" (at once). On the
/// viewer's own article it is faded and a tap only says why ("You can't repost your own article"); guests get the
/// sign-in prompt and nothing is sent.
class RepostButton extends StatelessWidget {
  const RepostButton({super.key, required this.article});

  final ArticleCard article;

  Future<void> _tap(BuildContext context, {required bool own}) async {
    if (own) {
      showActionMessage(context, context.l10n.repostOwnHint);
      return;
    }
    if (!requireAccount(context)) return;
    final engagement = context.read<EngagementCubit>();
    final current = engagement.of(article);
    // A repost request of the viewer's is in flight: its answer comes first.
    if (current.reposting) return;
    final action = await showRepostMenu(context, reposted: current.isReposted);
    if (action == null || !context.mounted) return;
    switch (action) {
      case RepostMenuAction.repost || RepostMenuAction.undo:
        final failure = await engagement.setReposted(article, reposted: action == RepostMenuAction.repost);
        if (context.mounted) showActionFailure(context, failure);
      case RepostMenuAction.withThoughts || RepostMenuAction.editThoughts:
        await showRepostCaptionSheet(context, article: article, editing: action == RepostMenuAction.editThoughts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final myId = context.select((SessionCubit c) => c.state.me?.id);
    final (count, reposted) = context.select((EngagementCubit c) {
      final engagement = c.state.of(article);
      return (engagement.repostCount, engagement.isReposted);
    });
    final own = myId != null && article.author?.id == myId;
    return Semantics(
      button: true,
      enabled: !own,
      toggled: own ? null : reposted,
      label: l10n.postBarRepost(count),
      hint: own ? l10n.repostOwnHint : null,
      onTap: () => unawaited(_tap(context, own: own)),
      excludeSemantics: true,
      child: ActionBarItem(
        icon: Icon(Icons.repeat_rounded, size: 22, color: reposted ? colors.primary : colors.textSecondary),
        count: count,
        active: reposted,
        dimmed: own,
        onTap: () => unawaited(_tap(context, own: own)),
      ),
    );
  }
}
