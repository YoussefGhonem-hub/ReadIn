import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scrolls the reader back to where the user left it (F04 resume, docs/api/contract-v1.md) and keeps it there while
/// the page settles.
///
/// [fraction] is a position in the scrollable range as the reading tracker measures it: `pixels / maxScrollExtent`
/// of the reader's own scroll view (`ReadingTracking`). The RDoc blocks are built lazily, so `maxScrollExtent` is an
/// estimate until the blocks around the target are laid out: [start] jumps, lets a frame lay them out, and jumps again
/// until the position stops moving. Sections that arrive later (related articles at the end) change the range again:
/// until the user scrolls, or for [holdFor], each change is followed by another round, so the restored position keeps
/// meaning what the tracker will measure.
///
/// While it jumps, [onNotification] holds the reader's scroll notifications back from the tracker, so an estimate that
/// overshoots never counts as a higher percent; each round hands the settled metrics to [onSettled] instead.
class ReaderResume {
  ReaderResume({
    required this.controller,
    required this.fraction,
    required this.onSettled,
    this.holdFor = const Duration(seconds: 3),
    Future<void> Function()? nextFrame,
  }) : _nextFrame = nextFrame ?? (() => WidgetsBinding.instance.endOfFrame);

  final ScrollController controller;

  /// 0–1, as the tracker sent it in `lastPosition`.
  final double fraction;

  /// Called with the reader's metrics once a round settled, for the tracker.
  final ValueChanged<ScrollMetrics> onSettled;

  /// How long changes of the scrollable range are followed when the user doesn't scroll.
  final Duration holdFor;

  final Future<void> Function() _nextFrame;

  /// Jumps per round. Each lays out the blocks around the target, so a few are enough even for long articles.
  static const maxPasses = 12;

  /// Close enough, in logical pixels: well under what `lastPosition`'s four decimals can tell apart.
  static const tolerance = 0.5;

  Timer? _hold;
  bool _holding = false;
  bool _jumping = false;
  bool _cancelled = false;

  /// False once the user scrolled, [cancel] was called or the hold ended with no round running.
  bool get isActive => !_cancelled && (_holding || _jumping);

  /// Runs the first round. Completes with true when the reader ended up below the top (false when the user scrolled
  /// first, the reader closed, or the article is too short to scroll).
  Future<bool> start() async {
    _holding = true;
    _hold = Timer(holdFor, () => _holding = false);
    await _settle();
    final moved = !_cancelled && controller.hasClients && controller.position.pixels > 0;
    if (!moved) cancel();
    return moved;
  }

  /// Stops following the range (the user scrolled, chose "Start over", or the reader changed the article).
  void cancel() {
    _cancelled = true;
    _holding = false;
    _hold?.cancel();
  }

  /// Feed it the notifications that bubble up from the reader's scroll view. Returns true for the ones the tracker
  /// must not see: all of them while jumping, and a change of the range that starts another round.
  bool onNotification(Notification notification) {
    if (_cancelled || notification is! ViewportNotificationMixin || notification.depth != 0) return false;
    if (_isUserScroll(notification)) {
      cancel();
      return false;
    }
    if (_jumping) return true;
    if (_holding && notification is ScrollMetricsNotification) {
      unawaited(_settle());
      return true;
    }
    return false;
  }

  static bool _isUserScroll(Notification notification) => switch (notification) {
        UserScrollNotification(:final direction) => direction != ScrollDirection.idle,
        ScrollStartNotification(:final dragDetails) => dragDetails != null,
        _ => false,
      };

  Future<void> _settle() async {
    if (_jumping) return;
    _jumping = true;
    try {
      for (var pass = 0; pass < maxPasses; pass++) {
        if (_cancelled || !controller.hasClients) return;
        final position = controller.position;
        final target = position.maxScrollExtent * fraction;
        if ((position.pixels - target).abs() <= tolerance) break;
        controller.jumpTo(target);
        // The next layout builds the blocks around the target and refines the range.
        await _nextFrame();
      }
    } finally {
      _jumping = false;
    }
    if (!_cancelled && controller.hasClients) onSettled(controller.position);
  }
}
