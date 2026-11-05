import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import 'reaction_bar.dart';
import 'reaction_visuals.dart';

/// The reaction button of the reader and the post card (F10, F34): a tap reacts with 💡 (or removes the viewer's
/// reaction); a long press opens the floating [ReactionBar], and sliding the finger onto a reaction and lifting it
/// picks that one. The icon becomes the viewer's reaction. Guests get the sign-in prompt.
class ReactionButton extends StatefulWidget {
  const ReactionButton({super.key, required this.article, this.showCount = false});

  final ArticleCard article;

  /// The post card's action bar: the icon with the reaction count beside it (none at 0), and the count in its
  /// accessible name ("React, 12").
  final bool showCount;

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  ReactionBarDrag? _drag;
  bool _open = false;

  ArticleCard get _article => widget.article;

  @override
  void dispose() {
    _drag?.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_open || !requireAccount(context)) return;
    final failure = await context.read<EngagementCubit>().tapReaction(_article);
    if (mounted) showActionFailure(context, failure);
  }

  /// Opens the bar; [drag] is the long press still down (null from a screen reader's long press).
  Future<void> _openBar({ReactionBarDrag? drag}) async {
    if (_open || !requireAccount(context)) return;
    _open = true;
    unawaited(HapticFeedback.selectionClick());
    final engagement = context.read<EngagementCubit>();
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final type = await showReactionBar(context, anchor: anchor, selected: engagement.of(_article).myReaction, drag: drag);
    _open = false;
    if (identical(_drag, drag)) {
      _drag?.dispose();
      _drag = null;
    }
    if (type == null || !mounted) return;
    final failure = await engagement.pickReaction(_article, type);
    if (mounted) showActionFailure(context, failure);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_open) return;
    _drag?.dispose();
    final drag = _drag = ReactionBarDrag();
    unawaited(_openBar(drag: drag));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (mine, count) = context.select((EngagementCubit c) {
      final engagement = c.state.of(_article);
      return (engagement.myReaction, engagement.reactionCount);
    });
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final String label;
    if (widget.showCount) {
      label = mine == null ? l10n.postBarReact(count) : l10n.postBarReacted(mine.label(l10n), count);
    } else {
      label = mine == null ? l10n.reactAction : l10n.removeReaction(mine.label(l10n));
    }
    // The icon changes to the viewer's reaction with a short pop (none with reduce motion).
    final Widget icon = TweenAnimationBuilder<double>(
      key: ValueKey('react-${mine?.name ?? 'none'}'),
      tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
      duration: reduceMotion ? Duration.zero : ReadInMotion.base,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: mine == null
          ? Icon(Icons.lightbulb_outline_rounded, size: widget.showCount ? 22 : 24, color: colors.textSecondary)
          : Text(
              mine.emoji,
              style: TextStyle(fontSize: widget.showCount ? 20 : 22, height: 1.2, fontFamilyFallback: emojiFontFallback),
            ),
    );
    return Semantics(
      button: true,
      selected: mine != null,
      label: label,
      onLongPressHint: l10n.chooseReaction,
      onTap: () => unawaited(_tap()),
      onLongPress: () => unawaited(_openBar()),
      excludeSemantics: true,
      // A long press opens the bar, so no tooltip (it would take the long press).
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: (details) => _drag?.move(details.globalPosition),
        onLongPressEnd: (details) => _drag?.release(details.globalPosition),
        child: widget.showCount
            ? ActionBarItem(icon: icon, count: count, active: mine != null, onTap: () => unawaited(_tap()))
            : InkWell(
                onTap: () => unawaited(_tap()),
                borderRadius: BorderRadius.circular(ReadInRadius.chip),
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : ReadInMotion.fast,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
                  decoration: BoxDecoration(
                    color: mine == null ? null : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(ReadInRadius.chip),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
              ),
      ),
    );
  }
}

/// One icon of the post card's action bar (F34): the icon with its count beside it, no text label, the count hidden
/// at 0. The caller gives it its accessible name (with the count) around it.
class ActionBarItem extends StatelessWidget {
  const ActionBarItem({super.key, required this.icon, this.count = 0, this.active = false, this.onTap, this.dimmed = false});

  final Widget icon;
  final int count;

  /// The viewer's own reaction or repost: the count in the primary color.
  final bool active;

  /// Not available to this viewer (e.g. reposting their own article): drawn faded, still tappable for the hint.
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.primary : colors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ReadInRadius.chip),
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (count > 0) ...[
                  const SizedBox(width: ReadInSpace.s1),
                  Text(
                    '$count',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The post card's reactions (F34): up to three emojis, the most used first, beside the action bar. A tap opens "who
/// reacted". Nothing while there are no reactions. [showTotal] adds the total after them.
class ReactionStackSummary extends StatelessWidget {
  const ReactionStackSummary({super.key, required this.reactions, required this.total, this.onTap, this.showTotal = true});

  final ReactionCounts reactions;
  final int total;
  final VoidCallback? onTap;
  final bool showTotal;

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
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final type in emojis)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 2),
                    child: Text(type.emoji, style: const TextStyle(fontSize: 14, height: 1.2, fontFamilyFallback: emojiFontFallback)),
                  ),
                if (showTotal) ...[
                  const SizedBox(width: ReadInSpace.s1),
                  Text('$total', style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                ],
              ],
            ),
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
