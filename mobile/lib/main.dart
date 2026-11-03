import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/session/session_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

/// Run with a flavor config:
///   flutter run --dart-define-from-file=config/dev.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await configureDependencies();

  final session = getIt<SessionCubit>()..start();
  runApp(ReadInApp(session: session, settings: getIt<SettingsCubit>()));
}
