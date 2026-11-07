import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../admin/presentation/admin_routes.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/support.dart';
import '../cubit/support_cubits.dart';
import '../widgets/support_widgets.dart';

/// The console's Tickets (`/admin/tickets`, `support.manage`, F35): Open (waiting longest first), Answered and Closed;
/// a category filter and a search (subject, member, or "#12").
class AdminTicketsPage extends StatelessWidget {
  const AdminTicketsPage({super.key, this.cubit});

  /// Test seam; the app takes the cubit from DI.
  final AdminTicketsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final allowed = context.select((SessionCubit c) => c.state.me?.canManageSupport ?? false);
    if (!allowed) return AdminNoAccessPage(title: context.l10n.adminSectionTickets);
    return BlocProvider(create: (_) => (cubit ?? getIt<AdminTicketsCubit>())..load(), child: const AdminTicketsView());
  }
}

class AdminTicketsView extends StatelessWidget {
  const AdminTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketsCubit>();
    final query = context.select((AdminTicketsCubit c) => c.state.query);
    void set(AdminTicketQuery next) => unawaited(cubit.setQuery(next));
    return DefaultTabController(
      length: SupportStatus.values.length,
      initialIndex: query.status.index,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminSectionTickets),
        bottom: TabBar(
          key: const ValueKey('admin-tickets-tabs'),
          onTap: (index) => set(query.copyWith(status: SupportStatus.values[index])),
          tabs: [
            Tab(text: l10n.supportStatusOpen),
            Tab(text: l10n.supportStatusAnswered),
            Tab(text: l10n.supportStatusClosed),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AdminPagedList<AdminTicketsCubit, AdminTicketRow, AdminTicketQuery>(
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSearchField(hint: l10n.supportSearchHint, initial: query.q, onSearch: (q) => set(query.copyWith(q: q))),
                  AdminChipRow(
                    children: [
                      AdminFilterChip(
                        label: l10n.moderationFilterAll,
                        selected: query.category == null,
                        onSelected: (_) => set(query.copyWith(category: () => null)),
                      ),
                      for (final category in SupportCategory.values)
                        AdminFilterChip(
                          label: l10n.supportCategory(category),
                          selected: query.category == category,
                          onSelected: (on) => set(query.copyWith(category: () => on ? category : null)),
                        ),
                    ],
                  ),
                ],
              ),
              countLabel: l10n.supportTicketsCount,
              emptyIcon: Icons.support_agent_rounded,
              emptyTitle: query.status == SupportStatus.open ? l10n.supportQueueEmptyOpen : l10n.supportQueueEmpty,
              itemBuilder: (context, ticket) => AdminTicketTile(
                ticket: ticket,
                onTap: () async {
                  await context.push<void>(AdminRoutes.ticket(ticket.id));
                  if (context.mounted) unawaited(cubit.refresh());
                },
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

