import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/admin/domain/entities/admin_dashboard.dart';
import '../features/admin/presentation/cubit/admin_summary_cubit.dart';
import '../features/admin/presentation/widgets/admin_entry.dart';
import '../features/auth/domain/entities/permissions.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/home/presentation/widgets/more_sheet.dart';
import '../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../shared/widgets/sign_in_prompt.dart';
import 'main_nav_bar.dart';

/// Bottom navigation shell: Explore · Write · (the ReadIn mark, Home) · Saved · More ([MainNavBar]); Profile opens from
/// the More sheet. It hands the app's unread count (F17) to the tabs' top bars and the More sheet, and re-reads it
/// when the app comes back to the foreground. On the console's branches (holders of `admin.access`, F23) it shows the
/// admin's bar instead ([AdminNavBar]).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Branches that need an account (guests get the soft sign-in prompt).
  static const _requiresAccount = {2, 3};

  final _unread = getIt<UnreadBadgeCubit>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_unread.refresh()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return BlocProvider.value(
      value: _unread,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AdminNavBar.isConsoleBranch(navigationShell.currentIndex)
            ? _ConsoleBar(navigationShell: navigationShell)
            : MainNavBar(
                currentIndex: navigationShell.currentIndex,
                onSelect: (index) {
                  final signedIn = context.read<SessionCubit>().state.isAuthenticated;
                  if (_requiresAccount.contains(index) && !signedIn) {
                    showSignInPrompt(context);
                    return;
                  }
                  navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
                },
                onMore: () => unawaited(showMoreSheet(context, unread: _unread)),
              ),
      ),
    );
  }
}

/// The admin's bar ([AdminNavBar], F23) for the console's branches: Tickets and Users for those with their
/// permissions, the open tickets from the console's summary (kept fresh while the bar shows) and the unread count.
class _ConsoleBar extends StatelessWidget {
  const _ConsoleBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.me);
    final unread = context.watch<UnreadBadgeCubit>().state;
    Widget bar(int openTickets) => AdminNavBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
          onMore: () => unawaited(showConsoleMoreSheet(context)),
          tickets: me?.can(Permissions.supportManage) ?? false,
          users: me?.can(Permissions.usersRead) ?? false,
          openTickets: openTickets,
          unread: unread,
        );
    final summary = adminSummaryCubit();
    if (summary == null) return bar(0);
    return AdminSummaryWatcher(
      cubit: summary,
      child: BlocBuilder<AdminSummaryCubit, AdminSummary?>(
        bloc: summary,
        builder: (_, state) => bar(state?.openTickets ?? 0),
      ),
    );
  }
}
