import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../article/domain/entities/article.dart';
import 'reaction_visuals.dart';

/// The finger of the long press that opened [ReactionBar], while it is still down: the reaction under it grows and
/// lifts, and lifting the finger on one picks it (F10, like LinkedIn). Lifting it anywhere else leaves the bar open
/// for a tap.
class ReactionBarDrag extends ChangeNotifier {
  Offset? _position;
  bool _released = false;

  /// Where the finger is, in global coordinates; null before it moves.
  Offset? get position => _position;

  /// The finger was lifted (at [position]).
  bool get released => _released;

  void move(Offset global) {
    if (_released) return;
    _position = global;
    notifyListeners();
  }

  void release([Offset? global]) {
    if (_released) return;
    if (global != null) _position = global;
    _released = true;
    notifyListeners();
  }
}

/// The four reactions in a floating bar (F10): emoji only, no numbers or text (each still has its name for screen
/// readers). They come in one after the other; the one under the finger grows and lifts; picking one plays a short
/// pop. With "reduce motion" (`MediaQuery.disableAnimations`) all of it is instant: no stagger, grow, lift or pop,
/// and a ring marks the reaction under the finger instead.
class ReactionBar extends StatefulWidget {
  const ReactionBar({super.key, this.selected, required this.onPicked, this.drag});

  /// The viewer's current reaction (picking it again removes it).
  final ReactionType? selected;

  /// Called once, after the pick animation.
  final ValueChanged<ReactionType> onPicked;

  /// The long press that opened the bar, if it is still down.
  final ReactionBarDrag? drag;

  /// Each reaction's square (its tap target).
  static const slot = 48.0;
  static const _emojiSize = 28.0;
  static const _grow = 1.55;
  static const _lift = 14.0;

  /// The whole entrance, the last reaction included.
  static const enterDuration = Duration(milliseconds: 360);
  static const pickDuration = Duration(milliseconds: 220);

  /// How far above and below the bar the finger may be and still point at a reaction: less than the gap to the middle
  /// of the button under it.
  static const _reach = 20.0;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: ReactionBar.enterDuration);
  late final AnimationController _pick = AnimationController(vsync: this, duration: ReactionBar.pickDuration);
  final _barKey = GlobalKey();
  final _slotKeys = {for (final type in ReactionType.values) type: GlobalKey()};
  ReactionType? _hovered;
  ReactionType? _picked;
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.drag?.addListener(_onDrag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_started) {
      _started = true;
      if (_reduceMotion) {
        _enter.value = 1;
      } else {
        unawaited(_enter.forward());
      }
    }
  }

  @override
  void didUpdateWidget(ReactionBar old) {
    super.didUpdateWidget(old);
    if (old.drag != widget.drag) {
      old.drag?.removeListener(_onDrag);
      widget.drag?.addListener(_onDrag);
    }
  }

  @override
  void dispose() {
    widget.drag?.removeListener(_onDrag);
    _enter.dispose();
    _pick.dispose();
    super.dispose();
  }

  void _onDrag() {
    final drag = widget.drag!;
    final hovered = drag.position == null ? null : _typeAt(drag.position!);
    if (drag.released) {
      drag.removeListener(_onDrag);
      if (hovered != null) {
        _choose(hovered);
      } else if (_hovered != null) {
        setState(() => _hovered = null);
      }
      return;
    }
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  /// The reaction whose column holds [global], when the finger is on the bar or near it.
  ReactionType? _typeAt(Offset global) {
    final bar = _rectOf(_barKey);
    // Not as far as the button that opened it: lifting the finger where it was pressed leaves the bar open.
    if (bar == null ||
        global.dx < bar.left ||
        global.dx > bar.right ||
        global.dy < bar.top - ReactionBar._reach ||
        global.dy > bar.bottom + ReactionBar._reach) {
      return null;
    }
    ReactionType? best;
    var bestDistance = double.infinity;
    for (final MapEntry(key: type, value: key) in _slotKeys.entries) {
      final rect = _rectOf(key);
      if (rect == null) continue;
      final distance = (rect.center.dx - global.dx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = type;
      }
    }
    return best;
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _choose(ReactionType type) async {
    if (_picked != null) return;
    setState(() {
      _picked = type;
      _hovered = null;
    });
    if (!_reduceMotion) await _pick.forward();
    if (mounted) widget.onPicked(type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final container = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.45, curve: Curves.easeOut));
    return FadeTransition(
      opacity: container,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(container),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.chooseReaction,
          child: Material(
            key: _barKey,
            color: colors.surfaceRaised,
            // Soft shadow in light mode, a lighter surface and a border in dark mode (SPEC §15.5).
            elevation: context.isDark ? 0 : 6,
            shadowColor: colors.textPrimary.withValues(alpha: 0.2),
            shape: StadiumBorder(side: BorderSide(color: colors.border)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, type) in ReactionType.values.indexed)
                    _Slot(
                      key: _slotKeys[type],
                      type: type,
                      index: i,
                      enter: _enter,
                      pick: _pick,
                      selected: type == widget.selected,
                      hovered: type == _hovered,
                      picked: _picked,
                      reduceMotion: _reduceMotion,
                      onTap: () => unawaited(_choose(type)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.type,
    required this.index,
    required this.enter,
    required this.pick,
    required this.selected,
    required this.hovered,
    required this.picked,
    required this.reduceMotion,
    required this.onTap,
  });

  final ReactionType type;
  final int index;
  final Animation<double> enter;
  final Animation<double> pick;
  final bool selected;
  final bool hovered;
  final ReactionType? picked;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = type.label(l10n);
    // One after the other: each starts 60 ms after the previous one and pops in with a small overshoot.
    final start = 0.1 + index * 0.16;
    final entrance = CurvedAnimation(parent: enter, curve: Interval(start, math.min(1, start + 0.42), curve: Curves.easeOutBack));
    final fade = CurvedAnimation(parent: enter, curve: Interval(start, math.min(1, start + 0.25)));
    final isPicked = picked == type;
    final grown = hovered && !reduceMotion;

    Widget emoji = Text(
      type.emoji,
      style: const TextStyle(fontSize: ReactionBar._emojiSize, height: 1.15, fontFamilyFallback: emojiFontFallback),
    );
    // The reaction under the finger grows and lifts (not with reduce motion).
    emoji = TweenAnimationBuilder<double>(
      tween: Tween(end: grown ? 1 : 0),
      duration: reduceMotion ? Duration.zero : ReadInMotion.fast,
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -ReactionBar._lift * t),
        child: Transform.scale(scale: 1 + (ReactionBar._grow - 1) * t, child: child),
      ),
      child: emoji,
    );
    // Picking pops the chosen reaction and fades the others.
    if (picked != null) {
      emoji = AnimatedBuilder(
        animation: pick,
        builder: (context, child) => Opacity(
          opacity: isPicked ? 1 : (1 - pick.value).clamp(0, 1),
          child: Transform.scale(scale: isPicked ? 1 + 0.6 * Curves.easeOut.transform(pick.value) : 1, child: child),
        ),
        child: emoji,
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? l10n.removeReaction(label) : label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: FadeTransition(
          opacity: fade,
          child: AnimatedBuilder(
            animation: entrance,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 12 * (1 - entrance.value)),
              child: Transform.scale(scale: 0.4 + 0.6 * entrance.value, child: child),
            ),
            child: SizedBox(
              width: ReactionBar.slot,
              height: ReactionBar.slot,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The current reaction sits on a tinted circle; with reduce motion a ring marks the one under the finger.
                  if (selected || (hovered && reduceMotion))
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? colors.primaryContainer : null,
                        border: hovered && reduceMotion ? Border.all(color: colors.primary, width: 2) : null,
                      ),
                    ),
                  emoji,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [ReactionBar] above [anchor] (global coordinates), or below it when there is no room, lined up with the
/// anchor's leading edge. [drag] is the long press that opened it, still down. Resolves to the reaction picked, or
/// null when dismissed (a tap outside, back).
///
/// The bar is an overlay entry over the current screen, not a route: pushing a route cancels the pointers that are
/// down, which would end the long press before the finger reaches a reaction. Back closes it (a pop entry on the
/// screen's route), and screen readers see only the bar and the dismiss area while it is open.
Future<ReactionType?> showReactionBar(
  BuildContext context, {
  required Rect anchor,
  ReactionType? selected,
  ReactionBarDrag? drag,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final route = ModalRoute.of(context);
  final completer = Completer<ReactionType?>();
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final direction = Directionality.of(context);
  final padding = MediaQuery.paddingOf(context);
  final dismissLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  late final OverlayEntry entry;
  late final _BarPopEntry popEntry;

  void close(ReactionType? type) {
    if (completer.isCompleted) return;
    completer.complete(type);
    route?.unregisterPopEntry(popEntry);
    entry.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) => entry.dispose());
  }

  popEntry = _BarPopEntry(() => close(null));
  entry = OverlayEntry(
    builder: (overlayContext) => MediaQuery(
      // The opener's "reduce motion", wherever the overlay sits.
      data: MediaQuery.of(overlayContext).copyWith(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: direction,
        child: BlockSemantics(
          child: Stack(
            children: [
              Positioned.fill(
                child: ModalBarrier(
                  dismissible: true,
                  semanticsLabel: dismissLabel,
                  color: Colors.transparent,
                  onDismiss: () => close(null),
                ),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: ReactionBarLayout(anchor: anchor, direction: direction, padding: padding),
                  child: ReactionBar(selected: selected, drag: drag, onPicked: close),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  route?.registerPopEntry(popEntry);
  return completer.future;
}

/// Back closes the bar instead of the screen under it.
class _BarPopEntry extends PopEntry<Object?> {
  _BarPopEntry(this._onBack);

  final VoidCallback _onBack;

  @override
  final ValueListenable<bool> canPopNotifier = ValueNotifier(false);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    // After the route is done with its pop entries: closing unregisters this one.
    if (!didPop) scheduleMicrotask(_onBack);
  }
}

/// Places the bar above the anchor (below it when there is no room), lined up with its leading edge, on screen.
class ReactionBarLayout extends SingleChildLayoutDelegate {
  ReactionBarLayout({required this.anchor, required this.direction, required this.padding});

  final Rect anchor;
  final TextDirection direction;
  final EdgeInsets padding;

  static const _gap = ReadInSpace.s1;
  static const _margin = ReadInSpace.s2;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final start = direction == TextDirection.ltr ? anchor.left : anchor.right - childSize.width;
    final x = start.clamp(_margin, math.max(_margin, size.width - childSize.width - _margin)).toDouble();
    final above = anchor.top - _gap - childSize.height;
    final y = above >= padding.top + _margin ? above : anchor.bottom + _gap;
    return Offset(x, y.clamp(padding.top, math.max(padding.top, size.height - childSize.height)).toDouble());
  }

  @override
  bool shouldRelayout(ReactionBarLayout old) => old.anchor != anchor || old.direction != direction || old.padding != padding;
}
