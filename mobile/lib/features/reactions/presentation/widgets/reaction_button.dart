import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import 'reaction_picker.dart';
import 'reaction_visuals.dart';

/// The reader's reaction button (F10): a tap reacts with 💡 (or removes the viewer's reaction), a long press opens
/// the picker. Guests get the sign-in prompt.
class ReactionButton extends StatelessWidget {
  const ReactionButton({super.key, required this.article});

  final ArticleCard article;

  Future<void> _tap(BuildContext context) async {
    if (!requireAccount(context)) return;
    final failure = await context.read<EngagementCubit>().tapReaction(article);
    if (context.mounted) showActionFailure(context, failure);
  }

  Future<void> _pick(BuildContext context) async {
    if (!requireAccount(context)) return;
    final engagement = context.read<EngagementCubit>();
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final type = await showReactionPicker(context, anchor: anchor, selected: engagement.of(article).myReaction);
    if (type == null || !context.mounted) return;
    final failure = await engagement.pickReaction(article, type);
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final mine = context.select((EngagementCubit c) => c.state.of(article).myReaction);
    final label = mine == null ? l10n.reactAction : l10n.removeReaction(mine.label(l10n));
    return Semantics(
      button: true,
      selected: mine != null,
      label: label,
      onLongPressHint: l10n.chooseReaction,
      excludeSemantics: true,
      // A long press opens the picker, so no tooltip (it would take the long press).
      child: InkWell(
        onTap: () => _tap(context),
        onLongPress: () => _pick(context),
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.fast,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
          decoration: BoxDecoration(
            color: mine == null ? null : colors.primaryContainer,
            borderRadius: BorderRadius.circular(ReadInRadius.chip),
          ),
          alignment: Alignment.center,
          child: mine == null
              ? Icon(Icons.lightbulb_outline_rounded, color: colors.textSecondary)
              : Text(mine.emoji, style: const TextStyle(fontSize: 22, height: 1.2, fontFamilyFallback: emojiFontFallback)),
        ),
      ),
    );
  }
}

/// Per-type counts, e.g. "💡 12  ❤️ 3" (only types with reactions). A tap opens "who reacted".
class ReactionSummary extends StatelessWidget {
  const ReactionSummary({super.key, required this.reactions, required this.total, this.onTap});

  final ReactionCounts reactions;

  /// Shown on its own when the API sent no per-type counts.
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final style =
        context.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w600).withEmoji();
    final types = [for (final type in ReactionType.values) if (reactions.of(type) > 0) type];
    return Semantics(
      button: onTap != null,
      label: [
        l10n.reactionsCount(total),
        for (final type in types) l10n.reactionCountSemantics(type.label(l10n), reactions.of(type)),
      ].join(l10n.listSeparator),
      onTapHint: l10n.showWhoReacted,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (types.isEmpty)
                  Text('💡 $total', style: style)
                else
                  for (final (i, type) in types.indexed) ...[
                    if (i > 0) const SizedBox(width: ReadInSpace.s2),
                    Text('${type.emoji} ${reactions.of(type)}', style: style),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
