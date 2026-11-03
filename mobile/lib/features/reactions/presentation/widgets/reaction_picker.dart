import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../article/domain/entities/article.dart';
import 'reaction_visuals.dart';

/// The four reactions in a row (F10). The viewer's current one is highlighted; choosing it again removes it.
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({super.key, this.selected, required this.onSelected});

  final ReactionType? selected;
  final ValueChanged<ReactionType> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceRaised,
      // Soft shadow in light mode, a lighter surface and a border in dark mode (SPEC §15.5).
      elevation: context.isDark ? 0 : 4,
      shadowColor: colors.textPrimary.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        side: BorderSide(color: colors.border),
      ),
      child: Semantics(
        container: true,
        label: context.l10n.chooseReaction,
        child: Padding(
          padding: const EdgeInsets.all(ReadInSpace.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in ReactionType.values)
                _Choice(type: type, selected: type == selected, onTap: () => onSelected(type)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.type, required this.selected, required this.onTap});

  final ReactionType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = type.label(context.l10n);
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? context.l10n.removeReaction(label) : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 26, height: 1.2, fontFamilyFallback: emojiFontFallback)),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: context.textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimaryContainer : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [ReactionPicker] next to [anchor] (global coordinates): above it when there is room, else below. Resolves
/// to the chosen reaction, or null when dismissed.
Future<ReactionType?> showReactionPicker(BuildContext context, {required Rect anchor, ReactionType? selected}) {
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showGeneralDialog<ReactionType>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: reduceMotion ? Duration.zero : ReadInMotion.fast,
    pageBuilder: (dialogContext, _, _) => CustomSingleChildLayout(
      delegate: _PickerLayout(anchor: anchor, direction: Directionality.of(context), padding: MediaQuery.paddingOf(context)),
      child: ReactionPicker(selected: selected, onSelected: (type) => Navigator.of(dialogContext).pop(type)),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(animation), child: child),
    ),
  );
}

class _PickerLayout extends SingleChildLayoutDelegate {
  _PickerLayout({required this.anchor, required this.direction, required this.padding});

  final Rect anchor;
  final TextDirection direction;
  final EdgeInsets padding;

  static const _gap = ReadInSpace.s2;
  static const _margin = ReadInSpace.s2;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Lined up with the button's leading edge, kept on screen.
    final start = direction == TextDirection.ltr ? anchor.left : anchor.right - childSize.width;
    final x = start.clamp(_margin, math.max(_margin, size.width - childSize.width - _margin)).toDouble();
    final above = anchor.top - _gap - childSize.height;
    final y = above >= padding.top + _margin ? above : anchor.bottom + _gap;
    return Offset(x, y.clamp(padding.top, math.max(padding.top, size.height - childSize.height)).toDouble());
  }

  @override
  bool shouldRelayout(_PickerLayout old) => old.anchor != anchor || old.direction != direction || old.padding != padding;
}
