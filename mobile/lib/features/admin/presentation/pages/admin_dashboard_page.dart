import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_widgets.dart' show ModerationUserRow;
import '../../../profile/presentation/profile_routes.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../admin_routes.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_chart.dart';
import '../widgets/admin_widgets.dart';

/// The console's dashboard (`/admin/dashboard`, `admin.access`, F23): the period, the cards with the change from the
/// previous period, the 30-day charts, the top lists, streak retention and the content pipeline.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, this.cubit});

  /// Test seam; the app takes the cubit from DI.
  final AdminDashboardCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.isAdmin ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionDashboard);
    return BlocProvider(
      create: (_) => (cubit ?? getIt<AdminDashboardCubit>())..load(),
      child: const AdminDashboardView(),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminDashboardCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSectionDashboard)),
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          final periods = PageBlock(
            margin: const EdgeInsets.only(top: PageBlock.gap),
            padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s2),
            child: _PeriodSwitch(selected: state.period, onSelected: (period) => unawaited(cubit.setPeriod(period))),
          );
          if (dashboard == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                periods,
                Expanded(
                  child: state.status == AdminDashboardStatus.failure
                      ? ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load()))
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final failure = await cubit.load();
              if (context.mounted) showActionFailure(context, failure);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
              children: [
                periods,
                if (state.status == AdminDashboardStatus.loading) const LinearProgressIndicator(minHeight: 2),
                if (state.status == AdminDashboardStatus.failure)
                  Padding(
                    padding: const EdgeInsets.all(PageBlock.gutter),
                    child: ErrorView(failure: state.failure!, compact: true, onRetry: () => unawaited(cubit.load())),
                  ),
                AnimatedOpacity(
                  duration: ReadInMotion.base,
                  opacity: state.status == AdminDashboardStatus.loading ? 0.5 : 1,
                  child: _DashboardBody(dashboard: dashboard),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Today · Yesterday · 7 days · 30 days.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.selected, required this.onSelected});

  final AdminPeriod selected;
  final ValueChanged<AdminPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(AdminPeriod period) => switch (period) {
          AdminPeriod.today => l10n.adminPeriodToday,
          AdminPeriod.yesterday => l10n.adminPeriodYesterday,
          AdminPeriod.days7 => l10n.adminPeriod7Days,
          AdminPeriod.days30 => l10n.adminPeriod30Days,
        };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in AdminPeriod.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
              child: ChoiceChip(
                key: ValueKey('admin-period-${period.wire}'),
                label: Text(label(period)),
                selected: period == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final me = context.select((SessionCubit c) => c.state.me);
    final cards = dashboard.cards;
    final canContent = me?.can(Permissions.moderationManage) ?? false;
    void open(String route) => unawaited(context.push<void>(route));

    final activity = <Widget>[
      _ValueCard(
        key: const ValueKey('card-articles'),
        label: l10n.adminCardArticlesPublished,
        value: cards.articlesPublished,
        onTap: canContent ? () => open(AdminRoutes.contentFor(from: dashboard.fromDate, to: dashboard.toDate)) : null,
      ),
      _ValueCard(
        key: const ValueKey('card-new-users'),
        label: l10n.adminCardNewUsers,
        value: cards.newUsers,
        detail: l10n.adminCardNewUsersSplit(
          adminNumber(cards.newUsers.phone),
          adminNumber(cards.newUsers.google),
          adminNumber(cards.newUsers.apple),
        ),
      ),
      _ValueCard(label: l10n.adminCardActiveReaders, value: cards.activeReaders),
      _ValueCard(label: l10n.adminCardReads, value: cards.reads),
      _ValueCard(label: l10n.adminCardComments, value: cards.comments),
      _ValueCard(label: l10n.adminCardReactions, value: cards.reactions),
      _ValueCard(label: l10n.adminCardReposts, value: cards.reposts),
    ];
    final now = <Widget>[
      if (cards.openReports case final count?)
        _StateCard(label: l10n.adminCardOpenReports, value: count, onTap: () => open(AdminRoutes.reports)),
      // The 24-hour target (F22 store additions): 0 is the goal.
      if (cards.openReportsOver24h case final count?)
        _StateCard(
          key: const ValueKey('card-reports-over-24h'),
          label: l10n.adminCardReportsOver24h,
          value: count,
          onTap: () => open(AdminRoutes.reports),
        ),
      if (cards.openTickets case final count?)
        _StateCard(label: l10n.adminCardOpenTickets, value: count, onTap: () => open(AdminRoutes.tickets)),
      if (cards.pendingVerifications case final count?)
        _StateCard(label: l10n.adminCardPendingVerifications, value: count, onTap: () => open(AdminRoutes.verification)),
      _StateCard(label: l10n.adminCardSuspendedNow, value: cards.suspendedNow),
    ];

    Widget chart(String title, List<int> values) {
      final total = values.fold<int>(0, (sum, v) => sum + v);
      final peak = values.fold<int>(0, (max, v) => v > max ? v : max);
      final caption = l10n.adminChartCaption(adminNumber(total), adminNumber(peak));
      return AdminChartCard(
        title: title,
        caption: caption,
        chart: AdminBarChart(values: values, semanticsLabel: '$title. $caption'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s2, PageBlock.gutter, 0),
          child: Text(
            l10n.adminDashboardRange(
              Bidi.ltrIsolate(dashboard.fromDate),
              Bidi.ltrIsolate(dashboard.toDate),
              adminTime(context, dashboard.generatedAt),
            ),
            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
        _Block(title: l10n.adminDashboardActivity, child: _CardGrid(children: activity)),
        _Block(title: l10n.adminDashboardNow, child: _CardGrid(children: now)),
        _Block(
          title: l10n.adminDashboardCharts,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              chart(l10n.adminCardNewUsers, [for (final day in dashboard.charts) day.newUsers]),
              const SizedBox(height: ReadInSpace.s3),
              chart(l10n.adminCardActiveReaders, [for (final day in dashboard.charts) day.activeReaders]),
              const SizedBox(height: ReadInSpace.s3),
              chart(l10n.adminCardArticlesPublished, [for (final day in dashboard.charts) day.articlesPublished]),
            ],
          ),
        ),
        _Block(
          title: l10n.adminTopArticles,
          child: dashboard.topArticles.isEmpty
              ? _Nothing(l10n.adminNothingInPeriod)
              : Column(
                  children: [
                    for (var i = 0; i < dashboard.topArticles.length; i++)
                      _TopArticleRow(rank: i + 1, article: dashboard.topArticles[i]),
                  ],
                ),
        ),
        _Block(
          title: l10n.adminTopWriters,
          child: dashboard.topWriters.isEmpty
              ? _Nothing(l10n.adminNothingInPeriod)
              : Column(
                  children: [
                    for (var i = 0; i < dashboard.topWriters.length; i++)
                      _TopWriterRow(rank: i + 1, writer: dashboard.topWriters[i]),
                  ],
                ),
        ),
        _Block(
          title: l10n.adminMissedSearches,
          subtitle: l10n.adminMissedSearchesHint,
          child: dashboard.missedSearches.isEmpty
              ? _Nothing(l10n.adminNothingInPeriod)
              : Column(children: [for (final search in dashboard.missedSearches) _MissedSearchRow(search: search)]),
        ),
        _Block(title: l10n.adminStreakRetention, subtitle: l10n.adminStreakRetentionHint, child: _Retention(retention: dashboard.streakRetention)),
        _Block(title: l10n.adminContentPipeline, child: _Pipeline(pipeline: dashboard.contentPipeline)),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => PageBlock(
        margin: const EdgeInsets.only(top: PageBlock.gap),
        padding: const EdgeInsets.all(PageBlock.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSectionTitle(title),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
                child: Text(subtitle!, style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ),
            child,
          ],
        ),
      );
}

class _Nothing extends StatelessWidget {
  const _Nothing(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary));
}

/// Two cards to a row.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: ReadInSpace.s3));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(ReadInRadius.md);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(ReadInSpace.s3), child: child),
      ),
    );
  }
}

/// A number of the period and its change from the previous period.
class _ValueCard extends StatelessWidget {
  const _ValueCard({super.key, required this.label, required this.value, this.detail, this.onTap});

  final String label;
  final DashboardValue value;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary))),
              if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
            ],
          ),
          const SizedBox(height: ReadInSpace.s1),
          Text(adminNumber(value.value), style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: ReadInSpace.s1),
          AdminChange(value: value),
          if (detail != null) ...[
            const SizedBox(height: ReadInSpace.s1),
            Text(detail!, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// "▲ 12 from the previous period", "▼ 3 …", or "Same as the previous period".
class AdminChange extends StatelessWidget {
  const AdminChange({super.key, required this.value});

  final DashboardValue value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final change = value.change;
    final (icon, color, text) = change > 0
        ? (Icons.arrow_upward_rounded, colors.success, l10n.adminChangeUp(adminNumber(change)))
        : change < 0
            ? (Icons.arrow_downward_rounded, colors.error, l10n.adminChangeDown(adminNumber(-change)))
            : (Icons.remove_rounded, colors.textSecondary, l10n.adminChangeSame);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Flexible(child: Text(text, style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

/// A number right now (no previous value), linking to its queue.
class _StateCard extends StatelessWidget {
  const _StateCard({super.key, required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary))),
              if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
            ],
          ),
          const SizedBox(height: ReadInSpace.s1),
          Text(
            adminNumber(value),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: value > 0 && onTap != null ? colors.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank(this.rank);

  final int rank;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        child: Text('$rank', style: context.textTheme.titleSmall?.copyWith(color: context.colors.textSecondary)),
      );
}

class _TopArticleRow extends StatelessWidget {
  const _TopArticleRow({required this.rank, required this.article});

  final int rank;
  final DashboardArticle article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return InkWell(
      onTap: () => unawaited(context.push<void>('/a/${Uri.encodeComponent(article.slug)}?lang=${article.language}')),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Rank(rank),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(
                    textDirection: article.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                    child: BidiText(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                  ),
                  const SizedBox(height: 2),
                  ModerationUserRow(user: article.author, avatarSize: 18),
                ],
              ),
            ),
            const SizedBox(width: ReadInSpace.s2),
            Text(l10n.adminReads(article.reads), style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TopWriterRow extends StatelessWidget {
  const _TopWriterRow({required this.rank, required this.writer});

  final int rank;
  final DashboardWriter writer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return InkWell(
      onTap: () => unawaited(context.push<void>(ProfileRoutes.of(writer.writer.username))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
        child: Row(
          children: [
            _Rank(rank),
            Expanded(child: ModerationUserRow(user: writer.writer, avatarSize: 28)),
            const SizedBox(width: ReadInSpace.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l10n.adminReads(writer.reads), style: context.textTheme.labelMedium),
                Text(l10n.adminArticlesRead(writer.articles), style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedSearchRow extends StatelessWidget {
  const _MissedSearchRow({required this.search});

  final MissedSearch search;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final direction = Bidi.detect(search.query) ?? (search.language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, size: 18, color: colors.textSecondary),
          const SizedBox(width: ReadInSpace.s2),
          Expanded(
            child: Text(
              search.query,
              textDirection: direction,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: ReadInSpace.s2),
          Text(context.l10n.adminSearchCount(search.count), style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _Retention extends StatelessWidget {
  const _Retention({required this.retention});

  final StreakRetention retention;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rate = retention.rate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rate == null ? '—' : '${(rate * 100).round()}%',
          textDirection: TextDirection.ltr,
          style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: ReadInSpace.s1),
        Text(
          l10n.adminStreakRetentionDetail(adminNumber(retention.kept), adminNumber(retention.cohort)),
          style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.pipeline});

  final ContentPipeline pipeline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = pipeline.lastSeedRunAt;
    return Column(
      children: [
        AdminInfoRow(label: l10n.adminPipelineFolders, value: adminNumber(pipeline.folders)),
        AdminInfoRow(label: l10n.adminPipelineSeeded, value: adminNumber(pipeline.seeded)),
        AdminInfoRow(label: l10n.adminPipelinePublished, value: adminNumber(pipeline.published)),
        AdminInfoRow(label: l10n.adminPipelineLastRun, value: last == null ? '—' : adminDateTime(context, last)),
      ],
    );
  }
}
