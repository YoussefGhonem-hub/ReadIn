import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/reading.dart';
import '../cubit/reading_stats_cubit.dart';

/// Reading stats (F08, F14): the streak, the last 7 and 30 days, all-time totals and top fields. Loads its own data
/// (`GET /me/stats`), so it works in the stats sheet and on the Profile tab alike; with [username] it shows that
/// user's public stats (`GET /users/{username}/stats`).
class ReadingStatsCard extends StatelessWidget {
  const ReadingStatsCard({super.key, this.username});

  /// Someone else's profile; null for the viewer's own stats.
  final String? username;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ReadingStatsCubit>()..load(username: username),
        child: BlocBuilder<ReadingStatsCubit, ReadingStatsState>(
          builder: (context, state) => switch (state.status) {
            ReadingLoadStatus.loading => const _StatsSkeleton(),
            ReadingLoadStatus.failure => Card(
                child: ErrorView(
                  failure: state.failure!,
                  compact: true,
                  onRetry: () => context.read<ReadingStatsCubit>().load(username: username),
                ),
              ),
            ReadingLoadStatus.ready => ReadingStatsView(stats: state.stats!, own: username == null),
          },
        ),
      );
}

class ReadingStatsView extends StatelessWidget {
  const ReadingStatsView({super.key, required this.stats, this.own = true});

  final ReadingStats stats;

  /// The viewer's own stats. Someone else's leave out the freeze line, which is advice for the reader.
  final bool own;

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
            _StreakHero(streak: stats.streak),
            if (own) ...[const SizedBox(height: ReadInSpace.s3), _FreezeLine(streak: stats.streak)],
            const Padding(padding: EdgeInsets.symmetric(vertical: ReadInSpace.s4), child: Divider()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PeriodTile(label: l10n.readingLast7Days, articles: stats.articlesThisWeek, minutes: stats.minutesThisWeek),
                ),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(child: _PeriodTile(label: l10n.readingLast30Days, articles: stats.articlesThisMonth)),
                const SizedBox(width: ReadInSpace.s2),
                Expanded(child: _PeriodTile(label: l10n.readingAllTime, articles: stats.totalArticles, minutes: stats.minutesRead)),
              ],
            ),
            if (stats.topFields.isNotEmpty) ...[
              const SizedBox(height: ReadInSpace.s4),
              Text(l10n.readingTopFields, style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s2),
              Wrap(
                spacing: ReadInSpace.s2,
                runSpacing: ReadInSpace.s2,
                children: [for (final field in stats.topFields) _TopFieldChip(field: field)],
              ),
            ] else if (stats.totalArticles == 0) ...[
              const SizedBox(height: ReadInSpace.s4),
              Text(own ? l10n.readingStatsEmpty : l10n.profileReadingStatsEmpty, style: context.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: colors.accentContainer, shape: BoxShape.circle),
          child: Icon(Icons.local_fire_department_rounded, size: 30, color: colors.accent),
        ),
        const SizedBox(width: ReadInSpace.s3),
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.readingDaysCount(streak.current),
                  style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                ),
                Text(l10n.readingCurrentStreak, style: context.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(width: ReadInSpace.s2),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.readingLongestStreak, style: context.textTheme.labelSmall),
              Text(l10n.readingDaysCount(streak.longest), style: context.textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Freeze status: pending (read today to keep the streak), ready, or used and coming back within 7 days.
class _FreezeLine extends StatelessWidget {
  const _FreezeLine({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (icon, background, accent, text) = streak.freezePending
        ? (Icons.ac_unit_rounded, colors.calloutWarning, colors.calloutWarningAccent, l10n.readingFreezePending)
        : streak.freezeAvailable
            ? (Icons.ac_unit_rounded, colors.calloutInfo, colors.calloutInfoAccent, l10n.readingFreezeAvailable)
            : (Icons.schedule_rounded, colors.surfaceVariant, colors.textSecondary, l10n.readingFreezeUsed);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ReadInRadius.md)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: ReadInSpace.s2),
          Expanded(child: Text(text, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary))),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.label, required this.articles, this.minutes});

  final String label;
  final int articles;
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.labelSmall),
          const SizedBox(height: ReadInSpace.s1),
          Text(l10n.readingArticlesCount(articles), style: context.textTheme.titleSmall),
          if (minutes != null) Text(l10n.readingMinutesCount(minutes!), style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TopFieldChip extends StatelessWidget {
  const _TopFieldChip({required this.field});

  final TopField field;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final color = FieldStyle.color(colors, field.color);
    return Semantics(
      label: l10n.readingTopFieldSemantics(field.name, l10n.readingArticlesCount(field.articles)),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: 6),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.12), colors.surface),
          borderRadius: BorderRadius.circular(ReadInRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FieldStyle.icon(field.icon), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              Bidi.isolateOppositeRuns(field.name, Directionality.of(context)),
              style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text('${field.articles}', style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(ReadInSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 52, height: 52, radius: 26),
                  SizedBox(width: ReadInSpace.s3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SkeletonBox(width: 96, height: 22), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 72)],
                  ),
                ],
              ),
              SizedBox(height: ReadInSpace.s3),
              SkeletonBox(height: 36, radius: ReadInRadius.md),
              SizedBox(height: ReadInSpace.s5),
              Row(
                children: [
                  Expanded(child: SkeletonBox(height: 44)),
                  SizedBox(width: ReadInSpace.s3),
                  Expanded(child: SkeletonBox(height: 44)),
                  SizedBox(width: ReadInSpace.s3),
                  Expanded(child: SkeletonBox(height: 44)),
                ],
              ),
            ],
          ),
        ),
      );
}
