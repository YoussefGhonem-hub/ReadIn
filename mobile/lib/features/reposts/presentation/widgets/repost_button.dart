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

/// Repost (F29) with its count beside it (none at 0), on the post card's action bar and in the reader's. A tap
/// reposts or undoes it at once and rolls back with a message when the API refuses. On the viewer's own article it is
/// faded and a tap only says why ("You can't repost your own article"); guests get the sign-in prompt and nothing is
/// sent.
class RepostButton extends StatelessWidget {
  const RepostButton({super.key, required this.article});

  final ArticleCard article;

  Future<void> _tap(BuildContext context, {required bool own}) async {
    if (own) {
      showActionMessage(context, context.l10n.repostOwnHint);
      return;
    }
    if (!requireAccount(context)) return;
    final failure = await context.read<EngagementCubit>().toggleRepost(article);
    if (context.mounted) showActionFailure(context, failure);
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
