import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

/// Registers everything annotated with @injectable / @lazySingleton / @module.
/// Regenerate with `dart run build_runner build -d`.
@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() => getIt.init();
