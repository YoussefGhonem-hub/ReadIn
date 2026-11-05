import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/reading.dart';
import '../cubit/reading_stats_cubit.dart';
import '../pages/reading_stats_page.dart';

/// The viewer's reading in three numbers (the Me sheet, Home's side column on tablets): the current streak, and the
/// articles and minutes of the last 7 days (`GET /me/stats`, F08). Tapping it opens Reading stats. Signed in only;
/// loads its own data.
class ReadingSummary extends StatelessWidget {
  const ReadingSummary({super.key, this.beforeOpen});

  /// Runs before Reading stats opens, e.g. closing the sheet this is in.
  final VoidCallback? beforeOpen;

  void _open(BuildContext context) {
    // Taken before [beforeOpen]: closing a sheet takes this context out of the tree.
    final router = GoRouter.maybeOf(context);
    beforeOpen?.call();
    if (router != null) unawaited(router.push<void>(ReadingStatsPage.path));
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ReadingStatsCubit>()..load(),
        child: Builder(
          builder: (context) {
            final colors = context.colors;
            final shape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ReadInRadius.md),
              side: BorderSide(color: colors.border),
            );
            return Material(
              color: colors.surface,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('reading-summary'),
                onTap: () => _open(context),
                customBorder: shape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                  child: BlocBuilder<ReadingStatsCubit, ReadingStatsState>(
                    builder: (context, state) => _SummaryRow(state: state),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state});

  final ReadingStatsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = state.stats;
    final loading = state.status == ReadingLoadStatus.loading;
    // A failed load keeps the shape with dashes; Reading stats, one tap away, says what went wrong.
    String value(int Function(ReadingStats s) of) => stats == null ? '–' : '${of(stats)}';
    final streak = stats?.streak.current ?? 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(
              value: stats == null ? '–' : '🔥 $streak',
              label: l10n.readingDaysInARow(streak),
              semanticsValue: value((s) => s.streak.current),
              loading: loading,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _Stat(value: value((s) => s.articlesThisWeek), label: l10n.meArticlesThisWeek, loading: loading),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _Stat(value: value((s) => s.minutesThisWeek), label: l10n.meMinutesThisWeek, loading: loading),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.loading, this.semanticsValue});

  final String value;
  final String label;
  final bool loading;

  /// What a screen reader hears for [value] (the streak without its 🔥).
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: loading ? null : context.l10n.profileStatSemantics(label, semanticsValue ?? value),
      excludeSemantics: !loading,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: Center(
                child: loading
                    ? const SkeletonBox(width: 36, height: 18)
                    : Text(
                        value,
                        maxLines: 1,
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700).withEmoji(),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
