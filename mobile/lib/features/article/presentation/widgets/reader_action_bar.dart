import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../comments/presentation/widgets/comments_sheet.dart';
import '../../../reactions/presentation/widgets/reaction_button.dart';
import '../../../reactions/presentation/widgets/who_reacted_sheet.dart';
import '../../../saved/presentation/widgets/save_button.dart';
import '../../domain/entities/article.dart';
import '../cubit/engagement_cubit.dart';

/// The reader's action bar (F04): reaction (tap 💡, long press for the picker), per-type counts that open "who
/// reacted", the comment count that opens the comments (F11), save and "add to collection". Counts follow
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
              CommentCount(count: engagement.commentCount, onTap: () => showCommentsSheet(context, article: article)),
              SaveToggleButton(article: article),
              AddToCollectionButton(article: article),
            ],
          ),
        ),
      ),
    );
  }
}

/// 💬 n; a tap opens the comments (F11).
class CommentCount extends StatelessWidget {
  const CommentCount({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: onTap != null,
      label: context.l10n.commentsCount(count),
      onTapHint: onTap == null ? null : context.l10n.commentsOpen,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
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
      ),
    );
  }
}
