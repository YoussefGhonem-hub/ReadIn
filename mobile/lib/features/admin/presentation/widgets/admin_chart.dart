import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';

/// A light 30-day bar chart (F23 dashboard): one bar a day, oldest at the start side (right in Arabic, left in
/// English), the last day in the full color. No axes; the caption under it gives the total and the peak, and screen
/// readers get [semanticsLabel].
class AdminBarChart extends StatelessWidget {
  const AdminBarChart({super.key, required this.values, required this.semanticsLabel, this.height = 72, this.color});

  final List<int> values;
  final String semanticsLabel;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarsPainter(
              values: values,
              color: color ?? colors.primary,
              faded: (color ?? colors.primary).withValues(alpha: 0.45),
              baseline: colors.border,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.values, required this.color, required this.faded, required this.baseline, required this.rtl});

  final List<int> values;
  final Color color;
  final Color faded;
  final Color baseline;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), line);
    if (values.isEmpty) return;
    final peak = values.fold<int>(0, math.max);
    final slot = size.width / values.length;
    final gap = math.min(2.0, slot * 0.25);
    final width = math.max(1.0, slot - gap);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final h = peak == 0 ? 0.0 : (value / peak) * (size.height - 2);
      if (h <= 0) continue;
      final x = rtl ? size.width - (i + 1) * slot + gap / 2 : i * slot + gap / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - 1 - h, width, h),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = i == values.length - 1 ? color : faded);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.color != color || old.faded != faded || old.baseline != baseline || old.rtl != rtl;
}

/// A chart in a card: its title, the bars and a caption.
class AdminChartCard extends StatelessWidget {
  const AdminChartCard({super.key, required this.title, required this.caption, required this.chart});

  final String title;
  final String caption;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(ReadInSpace.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.labelLarge),
          const SizedBox(height: ReadInSpace.s2),
          chart,
          const SizedBox(height: ReadInSpace.s2),
          Text(caption, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
