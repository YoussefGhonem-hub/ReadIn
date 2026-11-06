import 'package:flutter/material.dart';

/// The ReadIn mark of the app icon: a white "R" with the amber Arabic "ر" at its foot, on the brand's green. Drawn
/// from the icon's own outlines (`docs/design/app-store/logo/app-icon-1024.png`, 1024 units), so it stays sharp at
/// any size and needs no image asset.
class ReadInMark extends StatelessWidget {
  const ReadInMark({super.key, this.size = 56, this.background = true});

  final double size;

  /// Draws the round green background; without it only the two letters are drawn (e.g. over [ReadInMark.gradient]).
  final bool background;

  /// The icon's green: lighter where the light falls (top start), deep green in the far corner.
  static const gradient = RadialGradient(
    center: Alignment(-0.5, -0.65),
    radius: 1.35,
    colors: [Color(0xFF1C806A), Color(0xFF0F5E52), Color(0xFF083F36)],
    stops: [0, 0.55, 1],
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ReadIn',
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: ReadInMarkPainter(background: background)),
    ),
  );
}

/// Paints the mark into a square, letters centered. [ReadInMark] uses it; so can a button that draws its own ink.
class ReadInMarkPainter extends CustomPainter {
  const ReadInMarkPainter({this.background = true, this.scale = 0.9});

  final bool background;

  /// How large the letters are within the square (1 = as on the app icon).
  final double scale;

  /// The letters' bounds in the icon (1024 units): the "R" from x 259, the "ر" down to y 873.
  static const _bounds = Rect.fromLTRB(259, 316, 742, 873);

  static const _amber = LinearGradient(colors: [Color(0xFFF2B04E), Color(0xFFE8992E)]);

  static final Path _r = Path()
    ..fillType = PathFillType.evenOdd
    // Stem, bowl and leg.
    ..moveTo(259, 316)
    ..lineTo(462, 316)
    ..cubicTo(534, 316, 584, 366, 584, 442)
    ..cubicTo(584, 503, 560, 548, 506, 569)
    ..lineTo(590, 735)
    ..lineTo(489, 735)
    ..lineTo(415, 581)
    ..lineTo(349, 581)
    ..lineTo(349, 735)
    ..lineTo(259, 735)
    ..close()
    // The bowl's counter.
    ..moveTo(349, 395)
    ..lineTo(447, 395)
    ..cubicTo(474, 395, 490, 413, 490, 441)
    ..lineTo(490, 459)
    ..cubicTo(490, 487, 474, 505, 447, 505)
    ..lineTo(349, 505)
    ..close();

  static final Path _ra = Path()
    ..moveTo(728, 607)
    ..lineTo(737, 668)
    ..cubicTo(741, 695, 742, 715, 742, 735)
    ..cubicTo(742, 815, 690, 873, 610, 873)
    ..lineTo(592, 873)
    ..lineTo(592, 804)
    ..lineTo(612, 804)
    ..cubicTo(660, 804, 693, 780, 693, 735)
    ..cubicTo(693, 712, 690, 690, 686, 666)
    ..lineTo(679, 617)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    if (background) {
      final circle = Rect.fromCircle(center: center, radius: side / 2);
      canvas.drawOval(circle, Paint()..shader = ReadInMark.gradient.createShader(circle));
    }
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(side / 1024 * scale)
      ..translate(-_bounds.center.dx, -_bounds.center.dy)
      ..drawPath(_r, Paint()..color = Colors.white)
      ..drawPath(_ra, Paint()..shader = _amber.createShader(_ra.getBounds()))
      ..restore();
  }

  @override
  bool shouldRepaint(ReadInMarkPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.scale != scale;
}
