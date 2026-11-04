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

/// The reaction button of the reader and the post card (F10, F34): a tap reacts with 💡 (or removes the viewer's
/// reaction), a long press opens the picker. Guests get the sign-in prompt.
class ReactionButton extends StatelessWidget {
  const ReactionButton({super.key, required this.article, this.labeled = false});

  final ArticleCard article;

  /// The post card's action bar: "React" (or the viewer's reaction) next to the icon, and the whole width it gets.
  final bool labeled;

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
    if (labeled) return _labeled(context, mine, label);
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

  Widget _labeled(BuildContext context, ReactionType? mine, String semanticsLabel) {
    final colors = context.colors;
    final color = mine == null ? colors.textSecondary : colors.primary;
    return Semantics(
      button: true,
      selected: mine != null,
      label: semanticsLabel,
      onLongPressHint: context.l10n.chooseReaction,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _tap(context),
        onLongPress: () => _pick(context),
        borderRadius: BorderRadius.circular(ReadInRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (mine == null)
                Icon(Icons.lightbulb_outline_rounded, size: 20, color: color)
              else
                Text(mine.emoji, style: const TextStyle(fontSize: 18, height: 1.2, fontFamilyFallback: emojiFontFallback)),
              const SizedBox(width: ReadInSpace.s1),
              Flexible(
                child: Text(
                  mine == null ? context.l10n.postReact : mine.label(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The post card's reactions (F34): up to three emojis, the most used first, then the total. A tap opens "who
/// reacted". Nothing while there are no reactions.
class ReactionStackSummary extends StatelessWidget {
  const ReactionStackSummary({super.key, required this.reactions, required this.total, this.onTap});

  final ReactionCounts reactions;
  final int total;
  final VoidCallback? onTap;

  static const maxEmojis = 3;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    final present = [for (final type in ReactionType.values) if (reactions.of(type) > 0) type];
    // Most used first; equal counts keep the F10 order (💡 ❤️ 🔥 🤯).
    int byUse(ReactionType a, ReactionType b) {
      final count = reactions.of(b).compareTo(reactions.of(a));
      return count != 0 ? count : a.index.compareTo(b.index);
    }

    final types = ([...present]..sort(byUse)).take(maxEmojis).toList();
    final emojis = types.isEmpty ? [ReactionType.insightful] : types;
    return Semantics(
      button: onTap != null,
      label: [
        l10n.reactionsCount(total),
        for (final type in present) l10n.reactionCountSemantics(type.label(l10n), reactions.of(type)),
      ].join(l10n.listSeparator),
      onTapHint: l10n.showWhoReacted,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ReadInRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in emojis)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 2),
                  child: Text(type.emoji, style: const TextStyle(fontSize: 14, height: 1.2, fontFamilyFallback: emojiFontFallback)),
                ),
              const SizedBox(width: ReadInSpace.s1),
              Text('$total', style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
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
