import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../reactions/presentation/widgets/reaction_button.dart';
import '../../../reactions/presentation/widgets/who_reacted_sheet.dart';
import '../../../saved/presentation/widgets/save_button.dart';
import '../../domain/entities/article.dart';
import '../cubit/engagement_cubit.dart';

/// The reader's action bar (F04): reaction (tap 💡, long press for the picker), per-type counts that open "who
/// reacted", the comment count (display only until comments, F11), save and "add to collection". Counts follow
/// [EngagementCubit], so the viewer's actions and live counters (F27) show at once.
class ReaderActionBar extends StatelessWidget {
  const ReaderActionBar({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
          child: Row(
            children: [
              ReactionButton(article: article),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ReactionSummary(
                      reactions: engagement.reactions,
                      total: engagement.reactionCount,
                      onTap: () => showWhoReactedSheet(
                        context,
                        articleId: article.id,
                        reactions: engagement.reactions,
                        total: engagement.reactionCount,
                      ),
                    ),
                  ),
                ),
              ),
              CommentCount(count: engagement.commentCount),
              SaveToggleButton(article: article),
              AddToCollectionButton(article: article),
            ],
          ),
        ),
      ),
    );
  }
}

/// 💬 n, read-only until comments arrive (F11).
class CommentCount extends StatelessWidget {
  const CommentCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.commentsCount(count),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 20, color: colors.textSecondary),
              const SizedBox(width: ReadInSpace.s1),
              Text('$count', style: context.textTheme.labelLarge?.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
