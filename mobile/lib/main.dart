import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'app/live_session_bridge.dart';
import 'app/social_session_bridge.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/push/push_service.dart';
import 'core/realtime/realtime_service.dart';
import 'features/app_update/presentation/cubit/app_update_cubit.dart';
import 'features/article/data/datasources/article_offline_store.dart';
import 'features/auth/data/datasources/fresh_install_check.dart';
import 'features/auth/presentation/session/session_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'shared/media/media_cache_manager.dart';

/// Run with a flavor config (add `--dart-define=DEV_DEMO_PASSWORD=…` for one-tap demo sign in in debug builds):
///   flutter run --dart-define-from-file=config/dev.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaCacheManager.register(AppConfig.fromEnvironment());
  await Hive.initFlutter();
  await configureDependencies();
  // Deleting the app signs out: a new install forgets a session the Keychain kept (iOS), before it is restored.
  await getIt<FreshInstallCheck>().run();

  final session = getIt<SessionCubit>();
  unawaited(session.start()); // splash → POST /auth/refresh → the router applies the account guards
  final appUpdate = getIt<AppUpdateCubit>();
  unawaited(appUpdate.start()); // beside the restore, never holding up the splash: the saved policy, then the server's
  final push = getIt<PushService>();
  unawaited(push.start()); // never asks for permission by itself; a launch tap is kept until the router listens
  LiveSessionBridge(session, getIt<RealtimeService>(), push).start();
  final social = SocialStores(engagement: getIt(), follows: getIt(), collections: getIt());
  SocialSessionBridge(session, social.engagement, social.follows, social.collections, getIt<ArticleOfflineStore>()).start();
  runApp(ReadInApp(
    session: session,
    settings: getIt<SettingsCubit>(),
    social: social,
    appUpdate: appUpdate,
    pushOpens: push.openPaths,
  ));
}
