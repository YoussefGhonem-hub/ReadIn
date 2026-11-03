import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/reading.dart';
import '../cubit/reading_heatmap_cubit.dart';
import '../cubit/reading_stats_cubit.dart';
import 'heatmap_grid.dart';

/// GitHub-style reading heatmap for the last 12 months (F08, F14). Loads its own data (`GET /me/stats/heatmap`).
class ReadingHeatmap extends StatelessWidget {
  const ReadingHeatmap({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ReadingHeatmapCubit>()..load(),
        child: BlocBuilder<ReadingHeatmapCubit, ReadingHeatmapState>(
          builder: (context, state) => switch (state.status) {
            ReadingLoadStatus.loading => const _HeatmapFrame(
                child: SkeletonBox(height: _HeatmapLayout.labelHeight + 7 * _HeatmapLayout.step),
              ),
            ReadingLoadStatus.failure => Card(
                child: ErrorView(failure: state.failure!, compact: true, onRetry: context.read<ReadingHeatmapCubit>().load),
              ),
            ReadingLoadStatus.ready => ReadingHeatmapView(heatmap: state.heatmap!),
          },
        ),
      );
}

abstract final class _HeatmapLayout {
  static const cell = 11.0;
  static const gap = 3.0;
  static const step = cell + gap;
  static const labelHeight = 18.0;
}

/// Heatmap colors, all derived from the theme tokens: empty days in `border`, then 1 / 2 / 3+ articles in steps of
/// `primary`; freezes in the info accent with an outline so they don't rely on color alone.
class _HeatmapPalette {
  _HeatmapPalette(ReadInColors c)
      : levels = [
          c.border,
          Color.alphaBlend(c.primary.withValues(alpha: 0.35), c.surface),
          Color.alphaBlend(c.primary.withValues(alpha: 0.65), c.surface),
          c.primary,
        ],
        frozenFill = Color.alphaBlend(c.calloutInfoAccent.withValues(alpha: 0.25), c.surface),
        frozenBorder = c.calloutInfoAccent;

  final List<Color> levels;
  final Color frozenFill;
  final Color frozenBorder;
}

class ReadingHeatmapView extends StatelessWidget {
  const ReadingHeatmapView({super.key, required this.heatmap});

  final ReadingHeatmapData heatmap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // MaterialLocalizations counts from Sunday = 0 (Saturday in Arabic, Sunday in English).
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final grid = buildHeatmapGrid(heatmap, firstDayOfWeek: firstDay == 0 ? DateTime.sunday : firstDay);
    final palette = _HeatmapPalette(context.colors);

    return _HeatmapFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: l10n.readingHeatmapSemantics(grid.readingDays),
            // Newest week first on screen; in RTL the weeks run right to left, so time still flows to the inline end.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: _Grid(grid: grid, palette: palette),
            ),
          ),
          if (heatmap.days.isEmpty) ...[
            const SizedBox(height: ReadInSpace.s2),
            Text(l10n.readingHeatmapEmpty, style: context.textTheme.bodySmall),
          ],
          const SizedBox(height: ReadInSpace.s3),
          ExcludeSemantics(child: _Legend(palette: palette)),
        ],
      ),
    );
  }
}

class _HeatmapFrame extends StatelessWidget {
  const _HeatmapFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.readingActivity, style: context.textTheme.titleSmall)),
                Text(l10n.readingLast12Months, style: context.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: ReadInSpace.s3),
            child,
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.grid, required this.palette});

  final HeatmapGrid grid;
  final _HeatmapPalette palette;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final labelStyle = context.textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.2);
    String monthName(HeatmapMonthLabel label) => DateFormat.MMM(lang).format(_local(label.month));

    // Leave room after the last week for a month name that starts there, so the current month isn't cut off.
    var width = grid.weeks.length * _HeatmapLayout.step;
    if (grid.months.isNotEmpty) {
      final last = grid.months.last;
      final painter = TextPainter(
        text: TextSpan(text: monthName(last), style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      width = math.max(width, last.column * _HeatmapLayout.step + painter.width.ceilToDouble());
      painter.dispose();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          height: _HeatmapLayout.labelHeight,
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final label in grid.months)
                  PositionedDirectional(
                    start: label.column * _HeatmapLayout.step,
                    top: 0,
                    child: Text(monthName(label), style: labelStyle),
                  ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final week in grid.weeks)
              Column(children: [for (final cell in week) _Cell(cell: cell, palette: palette, languageCode: lang)]),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell, required this.palette, required this.languageCode});

  final HeatmapCell? cell;
  final _HeatmapPalette palette;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final cell = this.cell;
    if (cell == null) return const SizedBox.square(dimension: _HeatmapLayout.step);
    final box = _Swatch(
      color: cell.frozen ? palette.frozenFill : palette.levels[cell.level],
      border: cell.frozen ? palette.frozenBorder : null,
    );
    final l10n = context.l10n;
    final date = formatDate(_local(cell.date), languageCode);
    final label = cell.frozen
        ? l10n.readingHeatmapFrozenDay(date)
        : cell.articles > 0
            ? l10n.readingHeatmapDay(date, l10n.readingArticlesCount(cell.articles))
            : null;
    // Days without reading stay out of the accessibility tree; the grid's label gives the total.
    return label == null ? ExcludeSemantics(child: box) : Semantics(label: label, child: box);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.border});

  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
        width: _HeatmapLayout.cell,
        height: _HeatmapLayout.cell,
        margin: const EdgeInsets.all(_HeatmapLayout.gap / 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.5),
          border: border == null ? null : Border.all(color: border!, width: 1.5),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.palette});

  final _HeatmapPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textTheme.labelSmall;
    return Row(
      children: [
        Text(l10n.readingHeatmapLess, style: style),
        const SizedBox(width: ReadInSpace.s1),
        for (final color in palette.levels) _Swatch(color: color),
        const SizedBox(width: ReadInSpace.s1),
        Text(l10n.readingHeatmapMore, style: style),
        const Spacer(),
        _Swatch(color: palette.frozenFill, border: palette.frozenBorder),
        const SizedBox(width: ReadInSpace.s1),
        Text(l10n.readingHeatmapFreeze, style: style),
      ],
    );
  }
}

/// API dates are date-only UTC values; the formatters expect a local date.
DateTime _local(DateTime date) => DateTime(date.year, date.month, date.day);
