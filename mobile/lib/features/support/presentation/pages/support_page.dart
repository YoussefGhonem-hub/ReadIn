import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart' show AdminListSkeleton, AdminLoadMoreRow;
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';
import '../support_routes.dart';
import '../widgets/support_email.dart';
import '../widgets/support_widgets.dart';

/// Settings → «المساعدة والدعم» (`/settings/support`, F35): "New ticket", and My tickets in two tabs (active, closed),
/// latest activity first. The support email is one tap away.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key, this.from, this.ticketsCubit});

  /// The route the member came from, sent with a new ticket.
  final String? from;

  /// Test seam; the app takes the cubits from DI.
  final MyTicketsCubit Function(MyTicketsFilter filter)? ticketsCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = context.select((SessionCubit c) => c.state.me?.canContactSupport ?? false);
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.supportHelpTitle)),
        body: const Padding(padding: EdgeInsets.all(PageBlock.gutter), child: SupportEmailCard()),
      );
    }
    return DefaultTabController(
      length: MyTicketsFilter.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.supportHelpTitle),
          actions: [
            IconButton(
              key: const ValueKey('support-email'),
              tooltip: l10n.supportEmailUs,
              icon: const Icon(Icons.mail_outline_rounded),
              onPressed: () => unawaited(showSupportEmailSheet(context)),
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: l10n.supportTabActive), Tab(text: l10n.supportTabClosed)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('support-new-ticket'),
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(l10n.supportNewTicket),
          onPressed: () => unawaited(_newTicket(context)),
        ),
        body: TabBarView(
          children: [
            for (final filter in MyTicketsFilter.values)
              _KeepAlive(
                child: BlocProvider(
                  create: (_) => (ticketsCubit?.call(filter) ?? getIt<MyTicketsCubit>(param1: filter))..load(),
                  child: MyTicketsView(filter: filter),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _newTicket(BuildContext context) async {
    await context.push<void>(SupportRoutes.newTicketFrom(from ?? SupportRoutes.home));
  }
}

/// One tab of My tickets once its [MyTicketsCubit] is provided.
class MyTicketsView extends StatelessWidget {
  const MyTicketsView({super.key, required this.filter});

  final MyTicketsFilter filter;

  static const _loadMoreWithin = 400.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MyTicketsCubit>();
    Future<void> refresh() async {
      final failure = await cubit.refresh();
      if (context.mounted) showActionFailure(context, failure);
    }

    return BlocBuilder<MyTicketsCubit, MyTicketsState>(
      builder: (context, state) => switch (state.status) {
        SupportListStatus.loading => const AdminListSkeleton(),
        SupportListStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
        SupportListStatus.ready when state.items.isEmpty => RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: EmptyView(
                    icon: Icons.support_agent_rounded,
                    title: filter == MyTicketsFilter.active ? l10n.supportEmptyActive : l10n.supportEmptyClosed,
                    body: filter == MyTicketsFilter.active ? l10n.supportEmptyActiveBody : null,
                  ),
                ),
              ),
            ),
          ),
        SupportListStatus.ready => NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < _loadMoreWithin) unawaited(cubit.loadMore());
              return false;
            },
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: PageBlock.gap, bottom: 96),
                itemCount: state.items.length + (state.hasMore || state.moreFailure != null ? 1 : 0),
                itemBuilder: (context, index) => index < state.items.length
                    ? SupportTicketTile(
                        ticket: state.items[index],
                        onTap: () async {
                          await context.push<void>(SupportRoutes.ticket(state.items[index].id));
                          if (context.mounted) unawaited(cubit.refresh());
                        },
                      )
                    : AdminLoadMoreRow(failure: state.moreFailure, onRetry: () => unawaited(cubit.loadMore())),
              ),
            ),
          ),
      },
    );
  }
}

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

/// Settings → «المساعدة والدعم» (F35), for anyone who can send tickets.
class SupportEntryTile extends StatelessWidget {
  const SupportEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const ValueKey('settings-support'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.support_agent_rounded),
      title: Text(l10n.supportHelpTitle),
      subtitle: Text(l10n.supportEntryHint, style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => unawaited(context.push<void>(Uri(path: SupportRoutes.home, queryParameters: {'from': '/settings'}).toString())),
    );
  }
}
