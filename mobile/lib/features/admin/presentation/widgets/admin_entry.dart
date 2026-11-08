import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../admin_routes.dart';
import '../cubit/admin_summary_cubit.dart';
import 'admin_widgets.dart';

/// The app's [AdminSummaryCubit], or null where DI isn't set up (widget tests that don't need it).
AdminSummaryCubit? adminSummaryCubit() => getIt.isRegistered<AdminSummaryCubit>() ? getIt<AdminSummaryCubit>() : null;

/// Settings → «لوحة التحكم» (F23), the first row of Settings for holders of `admin.access`: opens the console, with
/// the badge (open reports + open tickets + pending verification requests). Shown, it keeps the badge fresh.
class AdminConsoleEntryTile extends StatelessWidget {
  const AdminConsoleEntryTile({super.key, this.cubit});

  /// Test seam; the app's singleton otherwise.
  final AdminSummaryCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final summary = cubit ?? adminSummaryCubit();
    // To the admin's bar (F23): from the app as a reader, the way back to the console.
    final tile = _EntryTile(onTap: () => context.go(AdminRoutes.consoleDashboard));
    if (summary == null) return tile;
    return BlocProvider.value(value: summary, child: AdminSummaryWatcher(cubit: summary, child: tile));
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final total = context.select((AdminSummaryCubit? c) => c?.state?.total);
    return ListTile(
      key: const ValueKey('settings-admin-console'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.admin_panel_settings_outlined),
      title: Text(l10n.adminConsoleTitle),
      subtitle: Text(
        total == null ? l10n.adminConsoleEntryHint : l10n.adminWaiting(total),
        style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [AdminCountBadge(count: total), const Icon(Icons.chevron_right_rounded)],
      ),
      onTap: onTap,
    );
  }
}

/// The console badge on an icon (the More sheet's tile, the Me sheet's row): [child] with the count, kept fresh while
/// shown; one queue's number with [count] (the admin's More sheet). Just [child] without DI.
class AdminSummaryBadge extends StatelessWidget {
  const AdminSummaryBadge({super.key, required this.child, this.cubit, this.count});

  final Widget child;
  final AdminSummaryCubit? cubit;

  /// The number shown; the total by default.
  final int? Function(AdminSummary summary)? count;

  @override
  Widget build(BuildContext context) {
    final summary = cubit ?? adminSummaryCubit();
    if (summary == null) return child;
    return AdminSummaryWatcher(
      cubit: summary,
      child: BlocBuilder<AdminSummaryCubit, AdminSummary?>(
        bloc: summary,
        builder: (context, state) {
          final total = (state == null ? null : (count == null ? state.total : count!(state))) ?? 0;
          if (total <= 0) return child;
          return Badge(
            label: Text(total > 9 ? '9+' : '$total'),
            backgroundColor: context.colors.error,
            textColor: context.colors.onError,
            child: child,
          );
        },
      ),
    );
  }
}
