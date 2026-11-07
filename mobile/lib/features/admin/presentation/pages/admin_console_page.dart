import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../admin_routes.dart';
import '../cubit/admin_summary_cubit.dart';
import '../widgets/admin_entry.dart';
import '../widgets/admin_widgets.dart';

/// One section of the compact console and the permission that opens it (F23, docs/api/contract-v1.md "Permissions and
/// sections"). The others (Taxonomy & Tags, Paths & Featured, Announcements, Audit log, System) are web only.
enum AdminConsoleSection {
  dashboard(Permissions.adminAccess, AdminRoutes.dashboard),
  users(Permissions.usersRead, AdminRoutes.users),
  content(Permissions.moderationManage, AdminRoutes.content),
  reports(Permissions.moderationManage, AdminRoutes.reports),
  tickets(Permissions.supportManage, AdminRoutes.tickets),
  verification(Permissions.verificationManage, AdminRoutes.verification);

  const AdminConsoleSection(this.permission, this.route);

  final String permission;
  final String route;

  /// The sections [me] may open, in the console's order.
  static List<AdminConsoleSection> of(Me me) => [for (final section in values) if (me.can(section.permission)) section];

  /// This section's number on the badge: open reports, open tickets, pending requests.
  int? countIn(AdminSummary? summary) => switch (this) {
        reports => summary?.openReports,
        tickets => summary?.openTickets,
        verification => summary?.pendingVerifications,
        _ => null,
      };
}

/// The console's home (`/admin`, `admin.access`): its sections as a list, the queues with their counts.
class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key, this.summary});

  /// Test seam; the app's singleton otherwise.
  final AdminSummaryCubit? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    if (me == null || !me.isAdmin) return AdminNoAccessPage(title: l10n.adminConsoleTitle);
    final cubit = summary ?? adminSummaryCubit();
    final view = AdminConsoleView(sections: AdminConsoleSection.of(me));
    if (cubit == null) return view;
    return BlocProvider.value(value: cubit, child: AdminSummaryWatcher(cubit: cubit, child: view));
  }
}

class AdminConsoleView extends StatelessWidget {
  const AdminConsoleView({super.key, required this.sections});

  final List<AdminConsoleSection> sections;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final summary = context.select((AdminSummaryCubit? c) => c?.state);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminConsoleTitle)),
      body: RefreshIndicator(
        onRefresh: () async => context.read<AdminSummaryCubit?>()?.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
          children: [
            PageBlock(
              margin: const EdgeInsets.only(top: PageBlock.gap),
              child: Column(
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: PageBlock.gutter, endIndent: PageBlock.gutter),
                    _SectionTile(section: sections[i], count: sections[i].countIn(summary)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(PageBlock.gutter),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.desktop_windows_outlined, size: 18, color: colors.textSecondary),
                  const SizedBox(width: ReadInSpace.s2),
                  Expanded(
                    child: Text(l10n.adminWebOnlyNote, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section, required this.count});

  final AdminConsoleSection section;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, hint) = switch (section) {
      AdminConsoleSection.dashboard => (Icons.insights_rounded, l10n.adminSectionDashboard, l10n.adminSectionDashboardHint),
      AdminConsoleSection.users => (Icons.people_alt_outlined, l10n.adminSectionUsers, l10n.adminSectionUsersHint),
      AdminConsoleSection.content => (Icons.article_outlined, l10n.adminSectionContent, l10n.adminSectionContentHint),
      AdminConsoleSection.reports => (Icons.flag_outlined, l10n.adminSectionReports, l10n.adminSectionReportsHint),
      AdminConsoleSection.tickets => (Icons.support_agent_rounded, l10n.adminSectionTickets, l10n.adminSectionTicketsHint),
      AdminConsoleSection.verification => (Icons.verified_outlined, l10n.adminSectionVerification, l10n.adminSectionVerificationHint),
    };
    return ListTile(
      key: ValueKey('admin-section-${section.name}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [AdminCountBadge(count: count), const Icon(Icons.chevron_right_rounded)],
      ),
      onTap: () async {
        final summary = context.read<AdminSummaryCubit?>();
        await context.push<void>(section.route);
        // Back from a queue: its count may have changed.
        unawaited(summary?.refresh());
      },
    );
  }
}
