import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/badges.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../cubit/streak_cubit.dart';
import 'reading_stats_sheet.dart';

/// The Home streak badge (F03, F08): the signed-in user's streak from [StreakCubit]; tapping it opens Reading stats.
/// Guests see the plain "start your streak" pill. Coming back to the app re-reads a stale streak (e.g. after midnight).
class HomeStreakBadge extends StatefulWidget {
  const HomeStreakBadge({super.key});

  @override
  State<HomeStreakBadge> createState() => _HomeStreakBadgeState();
}

class _HomeStreakBadgeState extends State<HomeStreakBadge> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => context.read<StreakCubit>().refreshIfStale());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final streak = context.select((StreakCubit c) => c.state);
    if (!signedIn) return const StreakBadge(days: 0);
    return StreakBadge(
      days: streak?.current ?? 0,
      notReadToday: streak?.notReadToday ?? false,
      freezePending: streak?.freezePending ?? false,
      onTap: () => showReadingStatsSheet(context),
    );
  }
}
