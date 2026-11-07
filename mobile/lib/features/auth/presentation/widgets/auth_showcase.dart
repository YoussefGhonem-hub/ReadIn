import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

/// The motion of the Sign in screen, after the web login (web/src/app/features/auth/auth-frame.css and
/// auth-showcase.css): the showcase cards rise in and then float, the form rises piece by piece, an error shakes once
/// and the main button shines once. With "reduce motion" (`MediaQuery.disableAnimations`) everything rests in its final
/// place.
abstract final class AuthMotion {
  /// Off in tests (test/flutter_test_config.dart): the screen renders at rest, so `pumpAndSettle` settles and the
  /// goldens show the final frame. The motion tests turn it back on.
  @visibleForTesting
  static bool enabled = true;

  /// The web's `cubic-bezier(0.2, 0.8, 0.2, 1)`.
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);

  /// Seconds until the entrance is over (the last card, the streak count, the shine). After that only the showcase's
  /// loops run.
  static const double entranceSeconds = 2.4;

  /// Seconds a piece of the form takes to rise.
  static const double riseSeconds = 0.6;
}

/// Drives the screen's motion from one ticker. [entranceOf] counts the seconds of the entrance and then stops changing,
/// so the form stops rebuilding; [loopOf] keeps counting for the showcase's loops. Both are null at rest.
class AuthMotionScope extends StatefulWidget {
  const AuthMotionScope({super.key, required this.child});

  final Widget child;

  static ValueListenable<double?> entranceOf(BuildContext context) => _of(context)?.entrance ?? _rest;

  static ValueListenable<double?> loopOf(BuildContext context) => _of(context)?.loop ?? _rest;

  static _AuthMotionData? _of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_AuthMotionData>();

  static final ValueListenable<double?> _rest = ValueNotifier<double?>(null);

  @override
  State<AuthMotionScope> createState() => _AuthMotionScopeState();
}

class _AuthMotionScopeState extends State<AuthMotionScope> with TickerProviderStateMixin {
  final _entrance = ValueNotifier<double?>(null);
  final _loop = ValueNotifier<double?>(null);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = AuthMotion.enabled && !MediaQuery.disableAnimationsOf(context);
    if (animate && _ticker == null) {
      _entrance.value = 0;
      _loop.value = 0;
      // Muted (and paused) while another route covers the screen.
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
    _entrance.value = math.min(seconds, AuthMotion.entranceSeconds);
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
  Widget build(BuildContext context) => _AuthMotionData(entrance: _entrance, loop: _loop, child: widget.child);
}

class _AuthMotionData extends InheritedWidget {
  const _AuthMotionData({required this.entrance, required this.loop, required super.child});

  final ValueListenable<double?> entrance;
  final ValueListenable<double?> loop;

  @override
  bool updateShouldNotify(_AuthMotionData old) => entrance != old.entrance || loop != old.loop;
}

/// 0 → 1 over [duration] seconds from [delay], eased; 1 at rest (no clock).
double _progress(double? t, double delay, double duration, [Curve curve = AuthMotion.ease]) =>
    t == null ? 1 : curve.transform(((t - delay) / duration).clamp(0.0, 1.0));

/// Where a loop of [period] seconds that starts at [delay] is (0 → 1); null before it starts and at rest.
double? _phase(double? t, double delay, double period) => t == null || t < delay ? null : ((t - delay) % period) / period;

/// A CSS keyframe track: the value at [at] (0 → 1) between `(offset, value)` stops, eased in and out between them.
double _track(double at, List<(double, double)> stops) {
  for (var i = 1; i < stops.length; i++) {
    final (end, to) = stops[i];
    if (at <= end) {
      final (start, from) = stops[i - 1];
      final f = end == start ? 1.0 : Curves.easeInOut.transform(((at - start) / (end - start)).clamp(0.0, 1.0));
      return from + (to - from) * f;
    }
  }
  return stops.last.$2;
}

/// Up at the middle of the loop, back at the end (`rd-sc-float`, the flame's flicker, the glows' drift).
const _upAndBack = [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)];

/// Rises into place (fades in from 14 px lower, 0.6 s) [delay] seconds after the screen opens, like the web form.
/// Give it a key when siblings can come and go (a banner), so each field keeps its state.
class AuthRise extends StatelessWidget {
  const AuthRise({super.key, required this.delay, required this.child});

  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double?>(
        valueListenable: AuthMotionScope.entranceOf(context),
        child: child,
        builder: (_, t, child) {
          final p = _progress(t, delay, AuthMotion.riseSeconds);
          // The same widgets at rest too, so nothing below is rebuilt from scratch when the entrance ends.
          return Opacity(
            opacity: p,
            alwaysIncludeSemantics: true,
            child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: child),
          );
        },
      );
}

/// Shakes [child] once when it appears, and again when [trigger] changes to another error (the web shakes its
/// `role="alert"`).
class AuthShake extends StatefulWidget {
  const AuthShake({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<AuthShake> createState() => _AuthShakeState();
}

class _AuthShakeState extends State<AuthShake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  var _appeared = false;

  /// The web's `rd-auth-shake`: −6, +6, −6, +6 px at 20, 40, 60 and 80 %.
  static const _stops = [0.0, -6.0, 6.0, -6.0, 6.0, 0.0];
  static const _curve = Cubic(0.36, 0.07, 0.19, 0.97);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appeared) {
      _appeared = true;
      _shake();
    }
  }

  @override
  void didUpdateWidget(AuthShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != null && widget.trigger != old.trigger) _shake();
  }

  void _shake() {
    if (AuthMotion.enabled && !MediaQuery.disableAnimationsOf(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _offset(double value) {
    if (value <= 0 || value >= 1) return 0;
    final at = _curve.transform(value) * (_stops.length - 1);
    final i = math.min(at.floor(), _stops.length - 2);
    return _stops[i] + (_stops[i + 1] - _stops[i]) * (at - i);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (_, child) => Transform.translate(offset: Offset(_offset(_controller.value), 0), child: child),
      );
}

/// The form's main button: a light sweeps across it once as the entrance ends (the web shines on hover, which phones
/// don't have), and it gives a little (98 %) while pressed.
class AuthButtonMotion extends StatefulWidget {
  const AuthButtonMotion({super.key, required this.child});

  final Widget child;

  /// When the light starts to sweep, and for how long (seconds).
  static const double shineAt = 1.0;
  static const double shineSeconds = 0.8;

  @override
  State<AuthButtonMotion> createState() => _AuthButtonMotionState();
}

class _AuthButtonMotionState extends State<AuthButtonMotion> {
  var _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final animate = AuthMotion.enabled && !MediaQuery.disableAnimationsOf(context);
    final shine = context.colors.onPrimary.withValues(alpha: 0.3);
    final rtl = context.isRtl;
    return Listener(
      onPointerDown: animate ? (_) => _press(true) : null,
      onPointerUp: animate ? (_) => _press(false) : null,
      onPointerCancel: animate ? (_) => _press(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: animate ? ReadInMotion.fast : Duration.zero,
        child: Stack(
          fit: StackFit.passthrough, // the button keeps the width it is given (full width in a form)
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ReadInRadius.md),
                  child: ValueListenableBuilder<double?>(
                    valueListenable: AuthMotionScope.entranceOf(context),
                    builder: (_, t, _) => CustomPaint(
                      painter: _ShinePainter(
                        at: t == null ? null : (t - AuthButtonMotion.shineAt) / AuthButtonMotion.shineSeconds,
                        color: shine,
                        rtl: rtl,
                      ),
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
  _ShinePainter({required this.at, required this.color, required this.rtl});

  /// 0 → 1 while the light sweeps; nothing outside that.
  final double? at;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final at = this.at;
    if (at == null || at <= 0 || at >= 1) return;
    // A band the button's width (bright in its middle) moves from just before the start edge to just past the end.
    final travel = Curves.easeInOut.transform(at) * 2.2 - 1.1;
    final rect = Offset((rtl ? -travel : travel) * size.width, 0) & size;
    final clear = color.withValues(alpha: 0);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, -0.4),
        end: const Alignment(1, 0.4),
        colors: [clear, color, clear],
        stops: const [0.3, 0.5, 0.7],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.at != at || old.color != color || old.rtl != rtl;
}

/// The showcase's colors: the brand green in light, a deep green in dark (as `.rd-sc` on the web).
class _Palette {
  factory _Palette.of(BuildContext context) {
    final c = context.colors;
    return context.isDark
        ? _Palette(top: c.primaryContainer, bottom: c.bg, ink: c.onPrimaryContainer, glow: c.primary, accent: c.accent)
        : _Palette(
            top: c.primary,
            bottom: Color.lerp(c.primary, c.textPrimary, 0.45)!,
            ink: c.onPrimary,
            glow: c.primaryContainer,
            accent: c.accent,
          );
  }

  const _Palette({required this.top, required this.bottom, required this.ink, required this.glow, required this.accent});

  final Color top;
  final Color bottom;

  /// Text and icons on the green.
  final Color ink;
  final Color glow;
  final Color accent;
}

/// The top of the Sign in screen, after the web login's showcase panel (AuthShowcase in auth-frame.ts): the brand green
/// with drifting light and a dot grid, the wordmark, the language switch, and a sample of the app floating on it
/// (today's article being read, a reading streak, a highlighted line). The sample is decorative: hidden from screen
/// readers, nothing to tap. The form's rounded sheet covers its last [sheetOverlap] pixels.
class AuthShowcaseHeader extends StatelessWidget {
  const AuthShowcaseHeader({super.key});

  /// How far the form's sheet reaches up over the header (its corner radius).
  static const double sheetOverlap = 28;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons on the green, in both themes.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.35, -1),
            end: const Alignment(0.35, 1),
            colors: [palette.top, palette.bottom],
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GlowPainter(palette: palette, clock: AuthMotionScope.loopOf(context), rtl: context.isRtl),
                  ),
                ),
              ),
              Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DotsPainter(palette.ink)))),
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: sheetOverlap + ReadInSpace.s2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TopRow(palette: palette),
                    const ExcludeSemantics(child: _Stage()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back (when there is a screen to go back to), the wordmark, and the UI language switch (as the web's auth frame).
class _TopRow extends StatelessWidget {
  const _TopRow({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (canPop) BackButton(color: palette.ink) else const SizedBox(width: ReadInSpace.s5),
          AppLogo(size: 22, color: palette.ink, accentColor: palette.accent),
          const Spacer(),
          _LanguageSwitch(palette: palette),
          const SizedBox(width: ReadInSpace.s4),
        ],
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final other = isArabic ? l10n.languageEnglish : l10n.languageArabic;
    return Semantics(
      button: true,
      label: l10n.switchLanguageTo(other),
      excludeSemantics: true,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: palette.ink,
          backgroundColor: palette.ink.withValues(alpha: 0.12),
          side: BorderSide(color: palette.ink.withValues(alpha: 0.2)),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
          textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.translate_rounded, size: 18),
        label: Text(other),
        onPressed: () => context.read<SettingsCubit>().setUiLanguage(isArabic ? 'en' : 'ar'),
      ),
    );
  }
}

/// Two soft lights drifting over the green (`rd-sc-glow`): the brand light at the top end, the accent at the bottom
/// start.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.palette, required this.clock, required this.rtl}) : super(repaint: clock);

  final _Palette palette;
  final ValueListenable<double?> clock;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    void glow(Offset center, double radius, Color color, double period, double delay) {
      final phase = _phase(t, delay, period);
      final k = phase == null ? 0.0 : _track(phase, _upAndBack);
      final c = center + Offset((rtl ? 48 : -48) * k, 40 * k);
      final r = radius * (1 + 0.15 * k);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final w = size.width;
    glow(Offset(rtl ? 30 : w - 30, 0), 170, palette.glow.withValues(alpha: 0.26), 18, 0);
    glow(Offset(rtl ? w - 80 : 80, size.height + 10), 190, palette.accent.withValues(alpha: 0.22), 24, -6);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.palette != palette || old.clock != clock || old.rtl != rtl;
}

/// A faint dot grid that fades out toward the edges (`rd-sc-dots`).
class _DotsPainter extends CustomPainter {
  _DotsPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 22.0;
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final rx = size.width * 0.75;
    final ry = size.height * 0.65;
    final paint = Paint();
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final dx = (x - center.dx) / rx;
        final dy = (y - center.dy) / ry;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d >= 1) continue;
        paint.color = ink.withValues(alpha: 0.16 * (1 - d));
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.ink != ink;
}

/// The three sample cards, laid out as on the web (a 460 × 320 stage) and scaled to the phone.
class _Stage extends StatelessWidget {
  const _Stage();

  static const _size = Size(460, 320);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          // As large as the whole screen allows: with the form under it, it still fits a 390 × 844 phone unscrolled.
          final scale = math.min(0.72, (constraints.maxWidth - 2 * ReadInSpace.s4) / _size.width);
          return SizedBox(
            width: _size.width * scale,
            height: _size.height * scale,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: _size,
                // A fixed picture: the system text size would only push the cards out of shape.
                child: MediaQuery.withNoTextScaling(
                  child: const Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PositionedDirectional(
                        start: 0,
                        top: 32,
                        child: _FloatingCard(width: 285, turn: -2, enter: 0.15, float: 7, child: _ArticleSample()),
                      ),
                      PositionedDirectional(
                        end: 0,
                        top: 0,
                        child: _FloatingCard(width: 172, turn: 4, enter: 0.35, float: 6, child: _StreakSample()),
                      ),
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: _FloatingCard(width: 250, turn: -3, enter: 0.55, float: 8, child: _QuoteSample()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// A tilted card that rises in [enter] seconds after the screen opens and then floats up and down every [float]
/// seconds (`rd-sc-in`, `rd-sc-float`).
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.width, required this.turn, required this.enter, required this.float, required this.child});

  final double width;

  /// Degrees.
  final double turn;
  final double enter;
  final double float;
  final Widget child;

  static const _riseSeconds = 0.9;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = RepaintBoundary(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(ReadInSpace.s4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [BoxShadow(color: colors.scrim, offset: const Offset(0, 26), blurRadius: 52, spreadRadius: -22)],
        ),
        child: child,
      ),
    );
    return ValueListenableBuilder<double?>(
      valueListenable: AuthMotionScope.loopOf(context),
      child: card,
      builder: (_, t, card) {
        final p = _progress(t, enter, _riseSeconds);
        final phase = _phase(t, enter + _riseSeconds, float);
        final lift = phase == null ? 0.0 : 12 * _track(phase, _upAndBack);
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 32 * (1 - p) - lift),
            child: Transform.rotate(
              angle: turn * math.pi / 180,
              child: Transform.scale(scale: 0.94 + 0.06 * p, child: card),
            ),
          ),
        );
      },
    );
  }
}

TextStyle? _small(BuildContext context) =>
    context.textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: context.colors.textSecondary);

/// Today's article being read: field, reading time, title, author and a reading progress bar that fills and fades.
class _ArticleSample extends StatelessWidget {
  const _ArticleSample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final author = l10n.authShowcaseAuthor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            InfoTag(label: l10n.authShowcaseField),
            const Spacer(),
            Icon(Icons.schedule_rounded, size: 12, color: colors.textSecondary),
            const SizedBox(width: ReadInSpace.s1),
            Text(l10n.authShowcaseMinutes, style: _small(context)),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        Text(
          l10n.authShowcaseArticle,
          style: text.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.6, color: colors.textPrimary),
        ),
        const SizedBox(height: ReadInSpace.s2),
        const _TextLine(widthFactor: 1),
        const SizedBox(height: 6),
        const _TextLine(widthFactor: 0.8),
        const SizedBox(height: ReadInSpace.s4),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
              child: Text(
                author.characters.first,
                style: text.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: ReadInSpace.s2),
            Text(author, style: text.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(width: ReadInSpace.s1),
            Icon(Icons.verified_rounded, size: 14, color: colors.success),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        const _ReadingProgress(),
      ],
    );
  }
}

/// A grey stand-in for a line of the article's text.
class _TextLine extends StatelessWidget {
  const _TextLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          height: 6,
          decoration: BoxDecoration(color: context.colors.surfaceVariant, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
        ),
      );
}

/// Fills to 68 % from the start edge, holds, fades and starts over every 5 s (`rd-sc-read`); at rest it shows 68 %.
class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
        child: ColoredBox(
          color: colors.surfaceVariant,
          child: SizedBox(
            height: 4,
            width: double.infinity,
            child: ValueListenableBuilder<double?>(
              valueListenable: AuthMotionScope.loopOf(context),
              builder: (_, t, _) {
                final phase = _phase(t, 1.2, 5);
                var fill = 0.68;
                var opacity = 1.0;
                if (phase != null) {
                  fill = _track(phase, const [(0, 0.04), (0.55, 0.68), (1, 0.68)]);
                  opacity = _track(phase, const [(0, 1), (0.88, 1), (1, 0)]);
                } else if (t != null) {
                  fill = 0.04; // waiting for the loop to start
                }
                return FractionallySizedBox(
                  widthFactor: fill,
                  heightFactor: 1,
                  alignment: AlignmentDirectional.centerStart,
                  child: Opacity(opacity: opacity, child: ColoredBox(color: colors.primary)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A 12-day reading streak: a flickering flame, the count rising from 0, and the week's days lighting up one by one.
class _StreakSample extends StatelessWidget {
  const _StreakSample();

  static const days = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.accentContainer, shape: BoxShape.circle),
              child: const _Flame(),
            ),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StreakCount(),
                  const SizedBox(height: ReadInSpace.s1),
                  Text(context.l10n.authShowcaseStreak, style: _small(context)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        const _StreakDays(),
      ],
    );
  }
}

class _Flame extends StatelessWidget {
  const _Flame();

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.local_fire_department_rounded, size: 20, color: context.colors.accent);
    return ValueListenableBuilder<double?>(
      valueListenable: AuthMotionScope.loopOf(context),
      child: icon,
      builder: (_, t, icon) {
        final phase = _phase(t, 0, 1.4);
        final k = phase == null ? 0.0 : _track(phase, _upAndBack);
        return Transform.rotate(angle: 4 * k * math.pi / 180, child: Transform.scale(scale: 1 + 0.14 * k, child: icon));
      },
    );
  }
}

class _StreakCount extends StatelessWidget {
  const _StreakCount();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: ReadInFonts.latin,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1,
      color: context.colors.textPrimary,
    );
    return ValueListenableBuilder<double?>(
      valueListenable: AuthMotionScope.entranceOf(context),
      builder: (_, t, _) => Text('${(_progress(t, 0.8, 1.4, Curves.easeOut) * _StreakSample.days).round()}', style: style),
    );
  }
}

/// Seven dots that light up one after another, hold, and dim together (`rd-sc-day`).
class _StreakDays extends StatelessWidget {
  const _StreakDays();

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 10),
    );
    return RepaintBoundary(
      child: ValueListenableBuilder<double?>(
        valueListenable: AuthMotionScope.loopOf(context),
        builder: (_, t, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              Builder(builder: (_) {
                final phase = _phase(t, 1 + i * 0.16, 4.5);
                var k = 1.0;
                if (phase != null) {
                  k = _track(phase, const [(0, 0), (0.08, 0), (0.18, 1), (0.88, 1), (1, 0)]);
                } else if (t != null) {
                  k = 0; // waiting for its turn
                }
                return Opacity(opacity: 0.3 + 0.7 * k, child: Transform.scale(scale: 0.5 + 0.5 * k, child: dot));
              }),
          ],
        ),
      ),
    );
  }
}

/// A highlighted line: the highlight sweeps in from the start edge, holds and clears every 6 s (`rd-sc-mark`).
class _QuoteSample extends StatelessWidget {
  const _QuoteSample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.flip(flipX: context.isRtl, child: Icon(Icons.format_quote_rounded, size: 20, color: colors.primary)),
        const SizedBox(height: ReadInSpace.s1),
        _MarkedText(
          text: l10n.authShowcaseQuote,
          style: context.textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.85, color: colors.textPrimary),
        ),
        const SizedBox(height: ReadInSpace.s2),
        Row(
          children: [
            Icon(Icons.border_color_outlined, size: 12, color: colors.textSecondary),
            const SizedBox(width: 6),
            Flexible(child: Text(l10n.authShowcaseHighlighted, style: _small(context))),
          ],
        ),
      ],
    );
  }
}

class _MarkedText extends StatefulWidget {
  const _MarkedText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_MarkedText> createState() => _MarkedTextState();
}

class _MarkedTextState extends State<_MarkedText> {
  final _painter = TextPainter();

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final direction = Directionality.of(context);
    final highlight = context.colors.highlight;
    final clock = AuthMotionScope.loopOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _painter
          ..text = TextSpan(text: widget.text, style: style)
          ..textDirection = direction
          ..textScaler = MediaQuery.textScalerOf(context)
          ..layout(maxWidth: constraints.maxWidth);
        return CustomPaint(
          size: _painter.size,
          painter: _MarkPainter(text: _painter, clock: clock, color: highlight, rtl: direction == TextDirection.rtl),
        );
      },
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.text, required this.clock, required this.color, required this.rtl}) : super(repaint: clock);

  final TextPainter text;
  final ValueListenable<double?> clock;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final phase = _phase(t, 1.6, 6);
    final grow = phase != null
        ? _track(phase, const [(0, 0), (0.3, 1), (0.88, 1), (1, 0)])
        : (t == null ? 1.0 : 0.0);
    if (grow > 0) {
      // One highlight per line (`box-decoration-break: clone`), each growing from the start edge.
      final lines = <double, Rect>{};
      for (final box in text.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.plainText.length))) {
        final rect = box.toRect();
        final key = (rect.center.dy / 4).roundToDouble();
        lines[key] = lines[key]?.expandToInclude(rect) ?? rect;
      }
      final paint = Paint()..color = color;
      for (final line in lines.values) {
        final full = Rect.fromLTRB(line.left - 2, line.top - 1, line.right + 2, line.bottom + 1);
        final width = full.width * grow;
        final rect = rtl
            ? Rect.fromLTRB(full.right - width, full.top, full.right, full.bottom)
            : Rect.fromLTWH(full.left, full.top, width, full.height);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
      }
    }
    text.paint(canvas, Offset.zero);
  }

  // The painter is laid out again whenever the widget rebuilds (a new language, a new width).
  @override
  bool shouldRepaint(_MarkPainter old) => true;
}
