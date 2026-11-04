import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/push/push_links.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../widgets/notification_tile.dart';

/// Notification center (F17). Opening it marks everything seen, so the bell's badge clears.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<NotificationsCubit>()..open(),
        child: const NotificationsView(),
      );
}

/// The list once a [NotificationsCubit] is provided: Today and Earlier, pull to refresh, more as you scroll, "Mark all
/// read", and "New notifications" when something arrives while it is open. Tapping a row marks it read and opens its
/// link like a push would.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// "New notifications": back to the top, and the first page again.
  Future<void> _showNew() async {
    if (_scroll.hasClients) unawaited(_scroll.animateTo(0, duration: ReadInMotion.base, curve: Curves.easeOutCubic));
    final failure = await context.read<NotificationsCubit>().refresh();
    if (mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NotificationsCubit>();
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          actions: [
            if (state.status == NotificationsStatus.ready && state.items.isNotEmpty)
              TextButton(
                onPressed: state.hasUnread ? () => _markAllRead(context) : null,
                child: Text(l10n.notificationsMarkAllRead),
              ),
            const SizedBox(width: ReadInSpace.s2),
          ],
        ),
        body: switch (state.status) {
          NotificationsStatus.loading => const _ListSkeleton(),
          NotificationsStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.refresh())),
          NotificationsStatus.ready => Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    final failure = await cubit.refresh();
                    if (context.mounted) showActionFailure(context, failure);
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) unawaited(cubit.loadMore());
                      return false;
                    },
                    child: state.items.isEmpty
                        ? CustomScrollView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: EmptyView(
                                  icon: Icons.notifications_none_rounded,
                                  title: l10n.notificationsEmptyTitle,
                                  body: l10n.notificationsEmptyBody,
                                ),
                              ),
                            ],
                          )
                        : _List(state: state, controller: _scroll),
                  ),
                ),
                if (state.hasNew)
                  PositionedDirectional(
                    top: ReadInSpace.s2,
                    start: ReadInSpace.s4,
                    end: ReadInSpace.s4,
                    child: Center(child: _NewItemsButton(onPressed: () => unawaited(_showNew()))),
                  ),
              ],
            ),
        },
      ),
    );
  }

  static Future<void> _markAllRead(BuildContext context) async {
    final failure = await context.read<NotificationsCubit>().markAllRead();
    if (context.mounted) showActionFailure(context, failure);
  }
}

/// Floats over the list's top while new notifications wait (F17), like the web's button.
class _NewItemsButton extends StatelessWidget {
  const _NewItemsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(elevation: 3, shadowColor: Colors.black38, visualDensity: VisualDensity.compact),
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_upward_rounded, size: 18),
          label: Text(context.l10n.notificationsNewItems),
        ),
      );
}

class _List extends StatelessWidget {
  const _List({required this.state, required this.controller});

  final NotificationsState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = NotificationClock.now();
    bool isToday(AppNotification n) {
      final at = n.updatedAt.toLocal();
      return at.year == now.year && at.month == now.month && at.day == now.day;
    }

    final today = state.items.where(isToday).toList();
    final earlier = state.items.where((n) => !isToday(n)).toList();
    final rows = <Widget>[
      if (today.isNotEmpty) _SectionHeader(l10n.notificationsToday),
      for (final n in today) NotificationTile(key: ValueKey(n.id), notification: n, onTap: () => _open(context, n)),
      if (earlier.isNotEmpty) _SectionHeader(l10n.notificationsEarlier),
      for (final n in earlier) NotificationTile(key: ValueKey(n.id), notification: n, onTap: () => _open(context, n)),
      _Footer(state: state),
    ];
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: ReadInSpace.s5),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  /// Read at once, then the link opens the same screen its push would. A link the app doesn't know, or one to the
  /// center itself (a moderation warning, whose notice the app shows by itself), opens nothing.
  static void _open(BuildContext context, AppNotification notification) {
    unawaited(context.read<NotificationsCubit>().markRead(notification));
    final path = pushLinkToPath(notification.link);
    if (path != null && path != centerPath) unawaited(context.push<void>(path));
  }

  static const centerPath = '/notifications';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s2),
        child: Semantics(
          header: true,
          child: Text(title, style: context.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<NotificationsCubit>().loadMore);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4), child: Center(child: child));
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s4),
        children: [
          for (var i = 0; i < 7; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: NotificationTile.leadingSize, height: NotificationTile.leadingSize, radius: 22),
                  SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(width: 180, height: 12),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(width: 64, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
