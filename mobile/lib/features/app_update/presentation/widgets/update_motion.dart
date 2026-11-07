import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';

/// The motion of "Update ReadIn":
/// - the illustration pops in and keeps working: a download fills the phone and the ring around it, waves spread out,
///   sparkles twinkle;
/// - the text and the button rise in after it;
/// - a light sweeps over the button every few seconds.
///
/// With "reduce motion" (`MediaQuery.disableAnimations`) everything rests in its final place.
abstract final class UpdateMotion {
  /// Off in tests (test/flutter_test_config.dart): the page renders at rest, so `pumpAndSettle` settles and the goldens
  /// show the final frame. test/features/app_update/update_motion_test.dart turns it back on.
  @visibleForTesting
  static bool enabled = true;

  /// The web's `cubic-bezier(0.2, 0.8, 0.2, 1)`, as on Sign in.
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);

  /// Seconds until the last piece has risen. After that only the loops run, and the text stops rebuilding.
  static const double entranceSeconds = 1.4;

  /// Seconds a piece of text takes to rise.
  static const double riseSeconds = 0.6;

  /// When the illustration pops in, and for how long (seconds).
  static const double heroAt = 0.1;
  static const double heroSeconds = 0.8;

  /// The light over the button: first at [shineAt] seconds, then every [shineEvery], each sweep [shineSeconds] long.
  static const double shineAt = 1.6;
  static const double shineEvery = 4.0;
  static const double shineSeconds = 0.9;
}

/// Drives the page's motion from one ticker. [entranceOf] counts the seconds of the entrance and then stops changing;
/// [loopOf] keeps counting for the illustration, the light behind it and the button's shine. Both are null at rest.
class UpdateMotionScope extends StatefulWidget {
  const UpdateMotionScope({super.key, required this.child});

  final Widget child;

  static ValueListenable<double?> entranceOf(BuildContext context) => _of(context)?.entrance ?? _rest;

  static ValueListenable<double?> loopOf(BuildContext context) => _of(context)?.loop ?? _rest;

  static _UpdateMotionData? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UpdateMotionData>();

  static final ValueListenable<double?> _rest = ValueNotifier<double?>(null);

  @override
  State<UpdateMotionScope> createState() => _UpdateMotionScopeState();
}

class _UpdateMotionScopeState extends State<UpdateMotionScope> with TickerProviderStateMixin {
  final _entrance = ValueNotifier<double?>(null);
  final _loop = ValueNotifier<double?>(null);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = UpdateMotion.enabled && !MediaQuery.disableAnimationsOf(context);
    if (animate && _ticker == null) {
      _entrance.value = 0;
      _loop.value = 0;
      _ticker = createTicker(_tick)..start();
    } else if (!animate && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _entrance.value = null;
      _loop.value = null;
    }
  }

  void _tick(Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _entrance.value = math.min(seconds, UpdateMotion.entranceSeconds);
    _loop.value = seconds;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _entrance.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _UpdateMotionData(entrance: _entrance, loop: _loop, child: widget.child);
}

class _UpdateMotionData extends InheritedWidget {
  const _UpdateMotionData({required this.entrance, required this.loop, required super.child});

  final ValueListenable<double?> entrance;
  final ValueListenable<double?> loop;

  @override
  bool updateShouldNotify(_UpdateMotionData old) => entrance != old.entrance || loop != old.loop;
}

/// 0 → 1 over [duration] seconds from [delay], eased; 1 at rest (no clock).
double _progress(double? t, double delay, double duration, [Curve curve = UpdateMotion.ease]) =>
    t == null ? 1 : curve.transform(((t - delay) / duration).clamp(0.0, 1.0));

/// Where a loop of [period] seconds that starts at [delay] is (0 → 1); null before it starts and at rest.
double? _phase(double? t, double delay, double period) =>
    t == null || t < delay ? null : ((t - delay) % period) / period;

/// 0 → 1 → 0 over a loop, eased in and out.
double _wave(double phase) => (1 - math.cos(2 * math.pi * phase)) / 2;

/// Rises into place (fades in from 16 px lower) [delay] seconds after the page opens.
class UpdateRise extends StatelessWidget {
  const UpdateRise({super.key, required this.delay, required this.child});

  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double?>(
    valueListenable: UpdateMotionScope.entranceOf(context),
    child: child,
    builder: (_, t, child) {
      final p = _progress(t, delay, UpdateMotion.riseSeconds);
      return Opacity(
        opacity: p,
        alwaysIncludeSemantics: true,
        child: Transform.translate(offset: Offset(0, 16 * (1 - p)), child: child),
      );
    },
  );
}

/// "Update now": a light sweeps across it every few seconds, so the eye finds it, and it gives a little (97 %) while
/// pressed.
class UpdateButtonMotion extends StatefulWidget {
  const UpdateButtonMotion({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateButtonMotion> createState() => _UpdateButtonMotionState();
}

class _UpdateButtonMotionState extends State<UpdateButtonMotion> {
  var _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final animate = UpdateMotion.enabled && !MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: animate ? (_) => _press(true) : null,
      onPointerUp: animate ? (_) => _press(false) : null,
      onPointerCancel: animate ? (_) => _press(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: animate ? ReadInMotion.fast : Duration.zero,
        child: Stack(
          fit: StackFit.passthrough, // the button keeps the full width it is given
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ReadInRadius.md),
                  child: CustomPaint(
                    painter: _ShinePainter(
                      clock: UpdateMotionScope.loopOf(context),
                      color: context.colors.onPrimary.withValues(alpha: 0.32),
                      rtl: context.isRtl,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter({required this.clock, required this.color, required this.rtl}) : super(repaint: clock);

  final ValueListenable<double?> clock;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    if (t == null || t < UpdateMotion.shineAt) return;
    final at = ((t - UpdateMotion.shineAt) % UpdateMotion.shineEvery) / UpdateMotion.shineSeconds;
    if (at >= 1) return;
    // A band the button's width (bright in its middle) moves from just before the start edge to just past the end.
    final travel = Curves.easeInOut.transform(at) * 2.2 - 1.1;
    final rect = Offset((rtl ? -travel : travel) * size.width, 0) & size;
    final clear = color.withValues(alpha: 0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.4),
          end: const Alignment(1, 0.4),
          colors: [clear, color, clear],
          stops: const [0.3, 0.5, 0.7],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.clock != clock || old.color != color || old.rtl != rtl;
}

/// Two soft lights behind the page, drifting slowly: the brand's at the top end, the accent's at the bottom start.
class UpdateBackdrop extends StatelessWidget {
  const UpdateBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = context.isDark;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BackdropPainter(
          clock: UpdateMotionScope.loopOf(context),
          brand: dark ? c.primaryContainer.withValues(alpha: 0.7) : c.primaryContainer.withValues(alpha: 0.9),
          accent: dark ? c.accent.withValues(alpha: 0.10) : c.accentContainer.withValues(alpha: 0.8),
          rtl: context.isRtl,
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.clock, required this.brand, required this.accent, required this.rtl})
    : super(repaint: clock);

  final ValueListenable<double?> clock;
  final Color brand;
  final Color accent;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final shown = _progress(t, 0, 0.8, Curves.easeOut);
    void glow(Offset center, double radius, Color color, double period, double delay) {
      final phase = _phase(t, delay, period);
      final k = phase == null ? 0.0 : _wave(phase);
      final c = center + Offset((rtl ? 40 : -40) * k, 32 * k);
      final r = radius * (1 + 0.12 * k);
      final tint = color.withValues(alpha: color.a * shown);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [tint, tint.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final w = size.width;
    final h = size.height;
    glow(Offset(rtl ? w * 0.12 : w * 0.88, h * 0.1), w * 0.8, brand, 18, 0);
    glow(Offset(rtl ? w * 0.9 : w * 0.1, h * 0.95), w * 0.75, accent, 24, 0);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.clock != clock || old.brand != brand || old.accent != accent || old.rtl != rtl;
}

/// The page's picture: a phone taking the update. It pops in, then loops: an arrow drops into the phone while a bar in
/// it and the ring around it fill, waves spread from the ring, and sparkles twinkle. Decorative: hidden from screen
/// readers.
class UpdateHero extends StatelessWidget {
  const UpdateHero({super.key});

  static const double size = 200;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size.square(size),
          painter: _HeroPainter(
            clock: UpdateMotionScope.loopOf(context),
            disc: c.primaryContainer,
            ink: c.onPrimaryContainer,
            ring: c.primary,
            sparkles: (c.accent, c.primary),
            rtl: context.isRtl,
          ),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.clock,
    required this.disc,
    required this.ink,
    required this.ring,
    required this.sparkles,
    required this.rtl,
  }) : super(repaint: clock);

  final ValueListenable<double?> clock;
  final Color disc;
  final Color ink;
  final Color ring;
  final (Color, Color) sparkles;
  final bool rtl;

  static const _discRadius = 56.0;
  static const _ringRadius = 67.0;

  /// The download fills, holds full for a moment and fades, then starts again; at rest it shows most of the way.
  static const _fillPeriod = 3.2;
  static const _restFill = 0.72;

  /// When the loops start: once the picture has popped in.
  static const _loopsAt = UpdateMotion.heroAt + 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final center = size.center(Offset.zero);

    // The pop: scales up from 60 % with a little overshoot, fading in.
    final pop = _progress(t, UpdateMotion.heroAt, UpdateMotion.heroSeconds, Curves.easeOutBack);
    final shown = _progress(t, UpdateMotion.heroAt, 0.35, Curves.easeOut);
    if (shown <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.6 + 0.4 * pop);
    canvas.translate(-center.dx, -center.dy);

    _waves(canvas, center, t, shown);

    // The disc and the ring's track.
    canvas.drawCircle(center, _discRadius, Paint()..color = disc.withValues(alpha: disc.a * shown));
    canvas.drawCircle(
      center,
      _ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = ring.withValues(alpha: 0.16 * shown),
    );

    // How far the download is, and how visible (it fades once full).
    final fillPhase = _phase(t, _loopsAt, _fillPeriod);
    final double fill;
    final double fillAlpha;
    if (t == null) {
      fill = _restFill;
      fillAlpha = 1;
    } else if (fillPhase == null) {
      fill = 0;
      fillAlpha = 0;
    } else {
      fill = Curves.easeInOutCubic.transform((fillPhase / 0.7).clamp(0.0, 1.0));
      fillAlpha = fillPhase < 0.82 ? 1 : 1 - (fillPhase - 0.82) / 0.18;
    }
    _ringFill(canvas, center, fill, fillAlpha * shown);
    _phone(canvas, center, t, fill, fillAlpha, shown);
    _sparkles(canvas, center, t, shown);
    canvas.restore();
  }

  /// Two waves spreading from the ring and fading, half a loop apart.
  void _waves(Canvas canvas, Offset center, double? t, double shown) {
    for (final delay in const [_loopsAt + 0.3, _loopsAt + 1.6]) {
      final q = _phase(t, delay, 2.6);
      if (q == null) continue;
      canvas.drawCircle(
        center,
        _ringRadius + 34 * Curves.easeOut.transform(q),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = ring.withValues(alpha: 0.32 * (1 - q) * shown),
      );
    }
  }

  /// The ring fills clockwise from the top, with a dot at its head.
  void _ringFill(Canvas canvas, Offset center, double fill, double alpha) {
    if (fill <= 0 || alpha <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = ring.withValues(alpha: alpha);
    final sweep = 2 * math.pi * fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: _ringRadius), -math.pi / 2, sweep, false, paint);
    final head = center + Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * _ringRadius;
    canvas.drawCircle(head, 4.2, Paint()..color = ring.withValues(alpha: alpha));
  }

  /// A phone outline; in it an arrow drops (fading in at the top, out at the bottom) over a bar that fills with the
  /// ring.
  void _phone(Canvas canvas, Offset center, double? t, double fill, double fillAlpha, double shown) {
    final body = Rect.fromCenter(center: center, width: 40, height: 64);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink.withValues(alpha: shown);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(9)), line);
    canvas.drawLine(Offset(center.dx - 5, body.top + 7), Offset(center.dx + 5, body.top + 7), line..strokeWidth = 2.6);

    // The arrow: 1.6 s a drop.
    final drop = _phase(t, _loopsAt, 1.6);
    final double dy;
    final double arrowAlpha;
    if (t == null) {
      dy = 0;
      arrowAlpha = 1;
    } else if (drop == null) {
      dy = -8;
      arrowAlpha = 0;
    } else {
      dy = -9 + 15 * Curves.easeInOut.transform(drop);
      arrowAlpha = drop < 0.2 ? drop / 0.2 : (drop > 0.75 ? (1 - drop) / 0.25 : 1);
    }
    final tip = Offset(center.dx, center.dy + 4 + dy);
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink.withValues(alpha: arrowAlpha * shown);
    canvas.drawLine(tip.translate(0, -15), tip, arrow);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx - 6.5, tip.dy - 6.5)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + 6.5, tip.dy - 6.5),
      arrow,
    );

    // The bar near the bottom of the screen, filling from the start edge.
    final track = Rect.fromCenter(center: Offset(center.dx, body.bottom - 11), width: 22, height: 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(2)),
      Paint()..color = ink.withValues(alpha: 0.22 * shown),
    );
    if (fill > 0 && fillAlpha > 0) {
      final filled = rtl
          ? Rect.fromLTRB(track.right - track.width * fill, track.top, track.right, track.bottom)
          : Rect.fromLTRB(track.left, track.top, track.left + track.width * fill, track.bottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(filled, const Radius.circular(2)),
        Paint()..color = ink.withValues(alpha: fillAlpha * shown),
      );
    }
  }

  /// Four-pointed sparkles around the ring, each twinkling on its own beat; at rest they shine steadily.
  void _sparkles(Canvas canvas, Offset center, double? t, double shown) {
    // (degrees from the top, clockwise; distance; size; accent or brand; delay)
    const stars = [
      (-42.0, 90.0, 8.0, true, 0.0),
      (34.0, 94.0, 5.5, false, 0.7),
      (128.0, 88.0, 6.5, true, 1.3),
      (220.0, 92.0, 5.0, false, 1.9),
    ];
    for (final (degrees, distance, radius, accent, delay) in stars) {
      final phase = _phase(t, _loopsAt + delay, 2.4);
      final double k;
      if (t == null) {
        k = 0.85;
      } else if (phase == null) {
        continue;
      } else {
        k = _wave(phase);
      }
      if (k <= 0.02) continue;
      final angle = (rtl ? -degrees : degrees) * math.pi / 180;
      final at = center + Offset(math.sin(angle), -math.cos(angle)) * distance;
      final r = radius * (0.4 + 0.6 * k);
      final color = accent ? sparkles.$1 : sparkles.$2;
      final w = r * 0.3;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - r)
          ..quadraticBezierTo(at.dx + w * 0.3, at.dy - w * 0.3, at.dx + r, at.dy)
          ..quadraticBezierTo(at.dx + w * 0.3, at.dy + w * 0.3, at.dx, at.dy + r)
          ..quadraticBezierTo(at.dx - w * 0.3, at.dy + w * 0.3, at.dx - r, at.dy)
          ..quadraticBezierTo(at.dx - w * 0.3, at.dy - w * 0.3, at.dx, at.dy - r)
          ..close(),
        Paint()..color = color.withValues(alpha: (0.35 + 0.65 * k) * shown),
      );
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.clock != clock ||
      old.disc != disc ||
      old.ink != ink ||
      old.ring != ring ||
      old.sparkles != sparkles ||
      old.rtl != rtl;
}
