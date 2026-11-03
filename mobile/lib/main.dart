import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'app/live_session_bridge.dart';
import 'core/di/injection.dart';
import 'core/push/push_service.dart';
import 'core/realtime/realtime_service.dart';
import 'features/auth/presentation/session/session_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'shared/media/media_cache_manager.dart';

/// Run with a flavor config:
///   flutter run --dart-define-from-file=config/dev.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaCacheManager.register();
  await Hive.initFlutter();
  await configureDependencies();

  final session = getIt<SessionCubit>()..start();
  final push = getIt<PushService>();
  unawaited(push.start()); // never asks for permission by itself; a launch tap is kept until the router listens
  LiveSessionBridge(session, getIt<RealtimeService>(), push).start();
  runApp(ReadInApp(session: session, settings: getIt<SettingsCubit>(), pushOpens: push.openPaths));
}
