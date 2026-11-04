import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/moderation.dart';
import '../cubit/moderation_list_cubit.dart';
import '../moderation_routes.dart';
import '../widgets/moderation_widgets.dart';

/// Moderation (F22), from Settings → Moderation, for `moderation.manage` only: the queue in three tabs (open, resolved,
/// dismissed) filtered by type, and the log. Each tab loads when first shown and keeps its place.
class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key, this.queueCubit, this.logCubit});

  /// Test seams; the app takes the cubits from DI.
  final ModerationQueueCubit Function(ReportStatus status)? queueCubit;
  final ModerationLogCubit Function()? logCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = context.select((SessionCubit c) => c.state.me?.isModerator ?? false);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.moderationTitle)),
        body: EmptyView(icon: Icons.lock_outline_rounded, title: l10n.moderationNoAccessTitle, body: l10n.moderationNoAccessBody),
      );
    }
    final tabs = [
      Tab(text: l10n.moderationTabOpen),
      Tab(text: l10n.moderationTabResolved),
      Tab(text: l10n.moderationTabDismissed),
      Tab(text: l10n.moderationTabLog),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.moderationTitle),
          bottom: TabBar(tabs: tabs, isScrollable: true, tabAlignment: TabAlignment.start),
        ),
        body: TabBarView(
          children: [
            for (final status in ReportStatus.values)
              _KeepAlive(
                child: BlocProvider(
                  create: (_) => (queueCubit?.call(status) ?? getIt<ModerationQueueCubit>(param1: status))..load(),
                  child: ModerationQueueView(status: status),
                ),
              ),
            _KeepAlive(
              child: BlocProvider(
                create: (_) => (logCubit?.call() ?? getIt<ModerationLogCubit>())..load(),
                child: const ModerationLogView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a case; back from it, [refresh] reads the list again (the case may have been acted on; the badge follows the
/// actions by itself).
Future<void> openModerationCase(BuildContext context, ModerationTargetRef target, {Future<Failure?> Function()? refresh}) async {
  await context.push<void>(ModerationRoutes.caseOf(target));
  if (context.mounted && refresh != null) unawaited(refresh());
}

/// One queue tab once its [ModerationQueueCubit] is provided.
class ModerationQueueView extends StatelessWidget {
  const ModerationQueueView({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (emptyTitle, emptyBody) = switch (status) {
      ReportStatus.open => (l10n.moderationEmptyOpenTitle, l10n.moderationEmptyOpenBody),
      ReportStatus.resolved => (l10n.moderationEmptyResolvedTitle, null),
      ReportStatus.dismissed => (l10n.moderationEmptyDismissedTitle, null),
    };
    return ModerationListView<ModerationQueueCubit, ModerationQueueItem>(
      emptyIcon: status == ReportStatus.open ? Icons.verified_user_outlined : Icons.inbox_outlined,
      emptyTitle: emptyTitle,
      emptyBody: emptyBody,
      itemBuilder: (context, item) => ModerationQueueTile(
        item: item,
        onTap: () => openModerationCase(context, item.ref, refresh: context.read<ModerationQueueCubit>().refresh),
      ),
    );
  }
}

/// The Log tab once its [ModerationLogCubit] is provided.
class ModerationLogView extends StatelessWidget {
  const ModerationLogView({super.key});

  @override
  Widget build(BuildContext context) => ModerationListView<ModerationLogCubit, ModerationLogEntry>(
        emptyIcon: Icons.history_rounded,
        emptyTitle: context.l10n.moderationEmptyLogTitle,
        separated: true,
        itemBuilder: (context, entry) => ModerationLogTile(
          entry: entry,
          onTap: () => openModerationCase(context, entry.ref, refresh: context.read<ModerationLogCubit>().refresh),
        ),
      );
}

/// A paged moderation list with the type filter: skeleton, error (offline included) with retry, empty, pull to refresh
/// and infinite scroll with a retry row when a later page fails.
class ModerationListView<C extends ModerationListCubit<T>, T> extends StatelessWidget {
  const ModerationListView({
    super.key,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptyIcon,
    this.emptyBody,
    this.separated = false,
  });

  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyBody;
  final IconData emptyIcon;

  /// Dividers between rows (the log) instead of cards (the queue).
  final bool separated;

  /// Load the next page this close to the end.
  static const _loadMoreWithin = 400.0;

  Future<void> _refresh(BuildContext context) async {
    final failure = await context.read<C>().refresh();
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<C>();
    return BlocBuilder<C, ModerationListState<T>>(
      builder: (context, state) => Column(
        children: [
          ModerationTypeFilter(selected: state.type, onSelected: cubit.setType),
          Divider(height: 1, color: context.colors.border),
          Expanded(
            child: switch (state.status) {
              ModerationListStatus.loading => const _ListSkeleton(),
              ModerationListStatus.failure => ErrorView(failure: state.failure!, onRetry: cubit.load),
              ModerationListStatus.ready when state.items.isEmpty => RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: EmptyView(icon: emptyIcon, title: emptyTitle, body: emptyBody),
                      ),
                    ),
                  ),
                ),
              ModerationListStatus.ready => NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < _loadMoreWithin) unawaited(cubit.loadMore());
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                      itemCount: state.items.length + (state.hasMore || state.moreFailure != null ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          separated ? Divider(height: 1, indent: ReadInSpace.s4, endIndent: ReadInSpace.s4, color: context.colors.border) : const SizedBox.shrink(),
                      itemBuilder: (context, index) => index < state.items.length
                          ? itemBuilder(context, state.items[index])
                          : _LoadMoreRow(failure: state.moreFailure, onRetry: cubit.loadMore),
                    ),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

/// The end of a list while the next page loads, or "Couldn't load more" with retry.
class _LoadMoreRow extends StatelessWidget {
  const _LoadMoreRow({required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Center(
          child: failure == null
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
                  children: [
                    Text(context.l10n.moderationLoadMoreFailed, style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                  ],
                ),
        ),
      );
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ReadInSpace.s4),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(width: 120),
            const SizedBox(height: ReadInSpace.s3),
            const SkeletonBox(height: 18),
            const SizedBox(height: ReadInSpace.s2),
            const SkeletonBox(width: 220),
            const SizedBox(height: ReadInSpace.s3),
            const SkeletonBox(width: 160, height: 20, radius: ReadInRadius.chip),
            const SizedBox(height: ReadInSpace.s6),
          ],
        ],
      );
}

/// Keeps a tab's list and scroll position while another tab is shown.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
