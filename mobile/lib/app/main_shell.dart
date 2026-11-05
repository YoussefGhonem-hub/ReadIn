import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/l10n/l10n_x.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../shared/widgets/sign_in_prompt.dart';

/// Bottom navigation shell: Today · Explore · Write · Saved · Profile. It hands the app's unread count (F17) to the
/// tabs' top bars, and re-reads it when the app comes back to the foreground.
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
    final l10n = context.l10n;
    final navigationShell = widget.navigationShell;
    return BlocProvider.value(
      value: _unread,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline))),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              final signedIn = context.read<SessionCubit>().state.isAuthenticated;
              if (_requiresAccount.contains(index) && !signedIn) {
                showSignInPrompt(context);
                return;
              }
              navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
            },
            destinations: [
              NavigationDestination(icon: const Icon(Icons.wb_sunny_outlined), selectedIcon: const Icon(Icons.wb_sunny), label: l10n.navHome),
              NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: l10n.navExplore),
              NavigationDestination(icon: const Icon(Icons.add_circle_outline), selectedIcon: const Icon(Icons.add_circle), label: l10n.navWrite),
              NavigationDestination(icon: const Icon(Icons.bookmark_border), selectedIcon: const Icon(Icons.bookmark), label: l10n.navSaved),
              NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.navProfile),
            ],
          ),
        ),
      ),
    );
  }
}
