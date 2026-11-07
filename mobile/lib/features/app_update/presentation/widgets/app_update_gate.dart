import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/app_update_cubit.dart';
import '../pages/update_required_page.dart';

/// Above the router (`MaterialApp.router`'s builder): while an update is required, [UpdateRequiredPage] replaces the
/// whole app, so no route, deep link or push tap gets past it. Checks again when the app returns to the foreground
/// ([AppUpdateCubit.resumed] keeps that to once every 30 minutes).
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child, this.launchStore = openStoreExternally});

  final Widget child;
  final StoreLauncher launchStore;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(context.read<AppUpdateCubit>().resumed()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppUpdateCubit, AppUpdateState>(
        builder: (context, state) => switch (state.requirement) {
          final requirement? => UpdateRequiredPage(requirement: requirement, launchStore: widget.launchStore),
          null => widget.child,
        },
      );
}
